#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

NFQWS_BIN="$ZAPRET_DIR/nfqws"
NFQWS2_BIN="$ZAPRET_DIR/nfqws2"
DEBUG_ENABLE=0
CURRENT_STRATEGY=""
ZAPRET_ENGINE=1
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

# Read interface-only list from config file (comma or newline separated).
# Result is stored in INTERFACE_ONLY as space-separated list (empty = all interfaces).
INTERFACE_ONLY=""
load_interface_only() {
    INTERFACE_ONLY=""
    [ -f "$INTERFACE_ONLY_FILE" ] || return 0
    raw="$(cat "$INTERFACE_ONLY_FILE" 2>/dev/null | tr ',' ' ' | tr '\n' ' ' | tr -s ' ')"
    # strip leading/trailing whitespace
    raw="$(printf '%s' "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -n "$raw" ] || return 0
    INTERFACE_ONLY="$raw"
    echo "- Interface-only mode: $INTERFACE_ONLY"
}

validate_preflight() {
    grep -q 'NFQUEUE' /proc/net/ip_tables_targets 2>/dev/null || {
        echo "! NFQUEUE is not available"
        return 1
    }

    CURRENT_STRATEGY="$(config_value "$CURRENT_STRATEGY_FILE" "general")"
    [ -f "$STRATEGY_DIR/$CURRENT_STRATEGY.sh" ] || {
        echo "! Strategy not found: $CURRENT_STRATEGY"
        return 1
    }
}

# Pick the DPI engine for the current strategy. A strategy may set ZAPRET=2 (in the
# sourced strategy file) to run under the zapret2 engine (nfqws2); default is 1 (nfqws).
select_engine() {
    case "$1" in
        2)
            ZAPRET_ENGINE=2
            NFQWS_BIN="$NFQWS2_BIN"
            ;;
        *)
            ZAPRET_ENGINE=1
            NFQWS_BIN="$ZAPRET_DIR/nfqws"
            ;;
    esac
    echo "- Engine: zapret$ZAPRET_ENGINE ($(basename "$NFQWS_BIN"))"
}

run_strategy() {
    config=""
    ZAPRET=1
    . "$STRATEGY_DIR/$CURRENT_STRATEGY.sh"
    # The QUIC any-protocol normalization is a zapret1 (nfqws) quirk. zapret2
    # strategies use the --lua-desync syntax and must pass through untouched.
    if [ "${ZAPRET:-1}" != "2" ]; then
        config="$(printf '%s\n' "$config" | sed -e 's/ --dpi-desync-any-protocol=1 --dpi-desync-fake-quic=/ --dpi-desync-fake-quic=/g' -e 's/ --dpi-desync-fake-quic=/ --dpi-desync-any-protocol=1 --dpi-desync-fake-quic=/g')"
    fi
    [ -n "$config" ] || {
        echo "! Strategy produced empty config: $CURRENT_STRATEGY"
        return 1
    }
    select_engine "${ZAPRET:-1}"
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
    if [ -n "$INTERFACE_ONLY" ]; then
        for _iface in $INTERFACE_ONLY; do
            append_unique_rule iptables mangle "$CHAIN_ZAPRET_POST" -o "$_iface" -p "$proto" $iptDPort $iCBo $iMark -j NFQUEUE --queue-num 200 --queue-bypass
            append_unique_rule iptables mangle "$CHAIN_ZAPRET_PRE"  -i "$_iface" -p "$proto" $iptSPort $iCBr $iMark -j NFQUEUE --queue-num 200 --queue-bypass
        done
    else
        append_unique_rule iptables mangle "$CHAIN_ZAPRET_POST" -p "$proto" $iptDPort $iCBo $iMark -j NFQUEUE --queue-num 200 --queue-bypass
        append_unique_rule iptables mangle "$CHAIN_ZAPRET_PRE" -p "$proto" $iptSPort $iCBr $iMark -j NFQUEUE --queue-num 200 --queue-bypass
    fi
}

ip6t_add() {
    proto="$1"
    port="$2"
    [ "$HAS_IP6TABLES" = "1" ] || return 0
    ip6tDPort="$i6MportD $port"
    ip6tSPort="$i6MportS $port"
    if [ -n "$INTERFACE_ONLY" ]; then
        for _iface in $INTERFACE_ONLY; do
            append_unique_rule ip6tables mangle "$CHAIN_ZAPRET_POST" -o "$_iface" -p "$proto" $ip6tDPort $i6CBo $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass
            append_unique_rule ip6tables mangle "$CHAIN_ZAPRET_PRE"  -i "$_iface" -p "$proto" $ip6tSPort $i6CBr $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass
        done
    else
        append_unique_rule ip6tables mangle "$CHAIN_ZAPRET_POST" -p "$proto" $ip6tDPort $i6CBo $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass
        append_unique_rule ip6tables mangle "$CHAIN_ZAPRET_PRE" -p "$proto" $ip6tSPort $i6CBr $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass
    fi
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
    # Confirm the NFQUEUE rules really landed. Lock contention / missing privileges
    # used to make this fail silently, leaving nfqws running with nothing queued.
    if ! iptables $IPT_LOCK_WAIT -t mangle -S "$CHAIN_ZAPRET_POST" 2>/dev/null | grep -q -- '-j NFQUEUE'; then
        echo "! WARNING: zapret NFQUEUE rules were NOT installed (iptables lock or permissions?)."
        echo "! Traffic is not being intercepted — DPI bypass will have no effect."
    fi
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
    load_interface_only
    apply_optional_network_tweaks
    validate_preflight || exit 1
    run_strategy || exit 1
    [ -x "$NFQWS_BIN" ] || {
        echo "! Engine binary for ZAPRET=$ZAPRET_ENGINE not found: $NFQWS_BIN"
        [ "$ZAPRET_ENGINE" = "2" ] && echo "! zapret2 (nfqws2) is not installed — use a ZAPRET=1 strategy or reinstall the module"
        exit 1
    }

    # zapret2 (nfqws2) has no built-in desync logic — the DPI attacks live in the
    # bundled Lua library, which must be loaded with --lua-init. Order matters:
    # zapret-lib.lua defines the primitives, zapret-antidpi.lua the desync funcs.
    ENGINE_LUA_ARGS=""
    if [ "$ZAPRET_ENGINE" = "2" ]; then
        if [ ! -f "$LUA_DIR/zapret-lib.lua" ] || [ ! -f "$LUA_DIR/zapret-antidpi.lua" ]; then
            echo "! zapret2 Lua scripts missing in $LUA_DIR (zapret-lib.lua, zapret-antidpi.lua)"
            echo "! Reinstall the module or pick a ZAPRET=1 strategy"
            exit 1
        fi
        ENGINE_LUA_ARGS="--lua-init=@$LUA_DIR/zapret-lib.lua --lua-init=@$LUA_DIR/zapret-antidpi.lua"
    fi

    [ "$DEBUG_ENABLE" = "1" ] && config="$config --debug=1"
    derive_ports
    apply_firewall_rules

    while [ "$STOP_REQUESTED" -eq 0 ]; do
        sh "$ZAPRET_DIR/make-unkillable.sh" >/dev/null 2>&1 &
        "$NFQWS_BIN" --uid=0:0 --bind-fix4 --bind-fix6 --qnum=200 $ENGINE_LUA_ARGS $config &
        NFQWS_PID=$!
        write_pidfile "$NFQWS_PID_FILE" "$NFQWS_PID"

        # Watchdog: kill nfqws if it becomes zombie or hangs (checked every 30s)
        (
            _wd_pid="$NFQWS_PID"
            while kill -0 "$_wd_pid" 2>/dev/null; do
                sleep 30
                [ "$STOP_REQUESTED" -eq 1 ] && exit 0
                # Check for zombie state
                _state="$(cat /proc/$_wd_pid/status 2>/dev/null | grep -m1 '^State:' | awk '{print $2}')"
                if [ "$_state" = "Z" ]; then
                    echo "! nfqws watchdog: zombie detected, restarting"
                    kill -KILL "$_wd_pid" 2>/dev/null || true
                    exit 0
                fi
                # Check if nfqws is still consuming the NFQUEUE (sanity: process must exist)
                if ! kill -CONT "$_wd_pid" 2>/dev/null; then
                    exit 0
                fi
            done
        ) &
        _wd_bg_pid=$!

        wait "$NFQWS_PID"
        kill "$_wd_bg_pid" 2>/dev/null || true
        wait "$_wd_bg_pid" 2>/dev/null || true

        remove_pidfile "$NFQWS_PID_FILE"
        NFQWS_PID=""
        [ "$STOP_REQUESTED" -eq 1 ] && break
        sleep 5
    done
}

main "$@"
