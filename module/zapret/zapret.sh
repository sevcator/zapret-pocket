#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

NFQWS_BIN="$STRATEGY_DIR/nfqws"
DEBUG_ENABLE=0
CURRENT_STRATEGY=""
HAS_IP6TABLES=0
STOP_REQUESTED=0
NFQWS_PID=""

boot_wait() {
    wait_for_boot_complete
}

setup_logging() {
    if [ "${CLI_DEBUG:-0}" = "1" ]; then
        DEBUG_ENABLE=1
        set -x
        return 0
    fi

    DEBUG_ENABLE="$(config_value "$DEBUG_FILE" "0")"
    if [ "$DEBUG_ENABLE" = "1" ]; then
        touch "$DEBUG_LOG"
        exec >>"$DEBUG_LOG" 2>&1
        set -x
    fi
}

detect_ipv6() {
    if command -v ip6tables >/dev/null 2>&1 && [ -r /proc/net/ip6_tables_targets ]; then
        HAS_IP6TABLES=1
    else
        HAS_IP6TABLES=0
    fi
}

validate_preflight() {
    grep -q 'NFQUEUE' /proc/net/ip_tables_targets 2>/dev/null || {
        echo "! NFQUEUE is not available"
        return 1
    }

    [ -x "$NFQWS_BIN" ] || {
        echo "! nfqws binary not found"
        return 1
    }

    CURRENT_STRATEGY="$(config_value "$CURRENT_STRATEGY_FILE" "general")"
    [ -f "$STRATEGY_DIR/$CURRENT_STRATEGY.sh" ] || {
        echo "! Strategy not found: $CURRENT_STRATEGY"
        return 1
    }
}

run_strategy() {
    config=""
    . "$STRATEGY_DIR/$CURRENT_STRATEGY.sh"
    config="$(printf '%s\n' "$config" | sed -e 's/ --dpi-desync-any-protocol=1 --dpi-desync-fake-quic=/ --dpi-desync-fake-quic=/g' -e 's/ --dpi-desync-fake-quic=/ --dpi-desync-any-protocol=1 --dpi-desync-fake-quic=/g')"
    [ -n "$config" ] || {
        echo "! Strategy produced empty config: $CURRENT_STRATEGY"
        return 1
    }
}

derive_ports() {
    tcp_ports="$(printf '%s\n' "$config" | grep -oE 'filter-tcp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' | sort -un)"
    udp_ports="$(printf '%s\n' "$config" | grep -oE 'filter-udp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' | sort -un)"
}

configure_match_flags() {
    if grep -q 'multiport' /proc/net/ip_tables_matches 2>/dev/null; then
        iMportS="-m multiport --sports"
        iMportD="-m multiport --dports"
    else
        iMportS="--sport"
        iMportD="--dport"
    fi

    if [ "$HAS_IP6TABLES" = "1" ] && grep -q 'multiport' /proc/net/ip6_tables_matches 2>/dev/null; then
        i6MportS="-m multiport --sports"
        i6MportD="-m multiport --dports"
    else
        i6MportS="--sport"
        i6MportD="--dport"
    fi

    if grep -q 'connbytes' /proc/net/ip_tables_matches 2>/dev/null; then
        iCBo="-m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:12"
        iCBr="-m connbytes --connbytes-dir=reply --connbytes-mode=packets --connbytes 1:3"
    else
        iCBo=""
        iCBr=""
    fi

    if [ "$HAS_IP6TABLES" = "1" ] && grep -q 'connbytes' /proc/net/ip6_tables_matches 2>/dev/null; then
        i6CBo="-m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:12"
        i6CBr="-m connbytes --connbytes-dir=reply --connbytes-mode=packets --connbytes 1:3"
    else
        i6CBo=""
        i6CBr=""
    fi

    if grep -q 'mark' /proc/net/ip_tables_matches 2>/dev/null; then
        iMark="-m mark ! --mark 0x40000000/0x40000000"
    else
        iMark=""
    fi

    if [ "$HAS_IP6TABLES" = "1" ] && grep -q 'mark' /proc/net/ip6_tables_matches 2>/dev/null; then
        i6Mark="-m mark ! --mark 0x40000000/0x40000000"
    else
        i6Mark=""
    fi
}

ipt_add() {
    proto="$1"
    port="$2"
    iptDPort="$iMportD $port"
    iptSPort="$iMportS $port"
    append_unique_rule iptables mangle "$CHAIN_ZAPRET_POST" -p "$proto" $iptDPort $iCBo $iMark -j NFQUEUE --queue-num 200 --queue-bypass
    append_unique_rule iptables mangle "$CHAIN_ZAPRET_PRE" -p "$proto" $iptSPort $iCBr $iMark -j NFQUEUE --queue-num 200 --queue-bypass
}

ip6t_add() {
    proto="$1"
    port="$2"
    [ "$HAS_IP6TABLES" = "1" ] || return 0
    ip6tDPort="$i6MportD $port"
    ip6tSPort="$i6MportS $port"
    append_unique_rule ip6tables mangle "$CHAIN_ZAPRET_POST" -p "$proto" $ip6tDPort $i6CBo $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass
    append_unique_rule ip6tables mangle "$CHAIN_ZAPRET_PRE" -p "$proto" $ip6tSPort $i6CBr $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass
}

add_multiport() {
    proto="$1"
    ports="$2"
    for current_port in $ports; do
        case "$current_port" in
            *-*)
                start_port="${current_port%-*}"
                end_port="${current_port#*-}"
                current_i="$start_port"
                while [ "$current_i" -le "$end_port" ]; do
                    ipt_add "$proto" "$current_i"
                    ip6t_add "$proto" "$current_i"
                    current_i=$((current_i + 1))
                done
                ;;
            *)
                ipt_add "$proto" "$current_port"
                ip6t_add "$proto" "$current_port"
                ;;
        esac
    done
}

apply_firewall_rules() {
    ensure_zapret_firewall_base
    configure_match_flags
    add_multiport "tcp" "$tcp_ports"
    add_multiport "udp" "$udp_ports"
}

terminate_child() {
    pid="$1"
    pidfile="$2"
    [ -n "$pid" ] || return 0
    kill -TERM "$pid" 2>/dev/null || true
    wait_for_exit "$pid" 5 || kill -KILL "$pid" 2>/dev/null || true
    remove_pidfile "$pidfile"
}

on_signal() {
    STOP_REQUESTED=1
    terminate_child "$NFQWS_PID" "$NFQWS_PID_FILE"
}

cleanup_runtime() {
    terminate_child "$NFQWS_PID" "$NFQWS_PID_FILE"
    cleanup_zapret_firewall
    restore_optional_network_tweaks
    remove_pidfile "$ZAPRET_PID_FILE"
}

main() {
    ensure_layout
    ensure_default_config

    if pidfile_is_running "$ZAPRET_PID_FILE"; then
        echo "- Service already running"
        exit 0
    fi

    write_pidfile "$ZAPRET_PID_FILE" "$$"
    trap on_signal INT TERM
    trap cleanup_runtime EXIT

    boot_wait
    setup_logging
    detect_ipv6
    apply_optional_network_tweaks
    validate_preflight || exit 1
    run_strategy || exit 1
    [ "$DEBUG_ENABLE" = "1" ] && config="$config --debug=1"
    derive_ports
    apply_firewall_rules

    while [ "$STOP_REQUESTED" -eq 0 ]; do
        sh "$STRATEGY_DIR/make-unkillable.sh" >/dev/null 2>&1 &
        "$NFQWS_BIN" --uid=0:0 --bind-fix4 --bind-fix6 --qnum=200 $config &
        NFQWS_PID=$!
        write_pidfile "$NFQWS_PID_FILE" "$NFQWS_PID"
        wait "$NFQWS_PID"
        remove_pidfile "$NFQWS_PID_FILE"
        NFQWS_PID=""
        [ "$STOP_REQUESTED" -eq 1 ] && break
        sleep 5
    done
}

main "$@"
