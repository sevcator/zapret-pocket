#!/system/bin/sh

MODPATH="${MODPATH:-/data/adb/modules/zapret}"
COMMON_FILE="${COMMON_FILE:-$MODPATH/common.sh}"
. "$COMMON_FILE"

DNSCRYPT_PROXY_BIN="${DNSCRYPT_PROXY_BIN:-$DNSCRYPT_DIR/dnscrypt-proxy}"
STOP_REQUESTED=0
DNSCRYPT_PID=""

setup_firewall() {
    ensure_dnscrypt_firewall_base

    if iptables_supported iptables nat; then
        # Redirect all DNS queries (including from mobile data PREROUTING) to dnscrypt-proxy
        append_unique_rule iptables nat "$CHAIN_DNSCRYPT_REDIRECT" -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:"$DNSCRYPT_PORT"
        append_unique_rule iptables nat "$CHAIN_DNSCRYPT_REDIRECT" -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:"$DNSCRYPT_PORT"
    fi

    # Block DoT (853) and direct DNS (53) leaks on IPv4
    if iptables_supported iptables filter; then
        for proto in udp tcp; do
            for dport in 853; do
                append_unique_rule iptables filter "$CHAIN_DNSCRYPT_OUTPUT"  -p "$proto" --dport "$dport" -j DROP
                append_unique_rule iptables filter "$CHAIN_DNSCRYPT_FORWARD" -p "$proto" --dport "$dport" -j DROP
            done
        done
    fi

    # Block DoT (853) and direct DNS (53) leaks on IPv6
    if iptables_supported ip6tables filter; then
        for proto in udp tcp; do
            for dport in 53 853; do
                append_unique_rule ip6tables filter "$CHAIN_DNSCRYPT_OUTPUT"  -p "$proto" --dport "$dport" -j DROP
                append_unique_rule ip6tables filter "$CHAIN_DNSCRYPT_FORWARD" -p "$proto" --dport "$dport" -j DROP
            done
        done
    fi
}

terminate_child() {
    pid="$1"
    [ -n "$pid" ] || return 0
    kill -TERM "$pid" 2>/dev/null || true
    wait_for_exit "$pid" 5 || kill -KILL "$pid" 2>/dev/null || true
    remove_pidfile "$DNSCRYPT_PID_FILE"
}

on_signal() {
    STOP_REQUESTED=1
    terminate_child "$DNSCRYPT_PID"
}

cleanup_runtime() {
    terminate_child "$DNSCRYPT_PID"
    cleanup_dnscrypt_firewall
    restore_dnscrypt_runtime_tweaks
    remove_pidfile "$DNSCRYPT_SUP_PID_FILE"
}

main() {
    ensure_layout
    ensure_default_config

    if pidfile_is_running "$DNSCRYPT_SUP_PID_FILE"; then
        echo "- dnscrypt supervisor already running"
        exit 0
    fi

    [ -x "$DNSCRYPT_PROXY_BIN" ] || {
        echo "! dnscrypt-proxy not found" >&2
        exit 1
    }
    [ -f "$DNSCRYPT_DIR/dnscrypt-proxy.toml" ] || {
        echo "! dnscrypt-proxy.toml not found" >&2
        exit 1
    }

    write_pidfile "$DNSCRYPT_SUP_PID_FILE" "$$"
    trap on_signal INT TERM
    trap cleanup_runtime EXIT

    apply_dnscrypt_runtime_tweaks
    setup_firewall
    cd "$DNSCRYPT_DIR" || {
        echo "! Failed to enter DNSCrypt directory: $DNSCRYPT_DIR" >&2
        exit 1
    }

    while [ "$STOP_REQUESTED" -eq 0 ]; do
        "$DNSCRYPT_PROXY_BIN" >/dev/null 2>&1 &
        DNSCRYPT_PID=$!
        write_pidfile "$DNSCRYPT_PID_FILE" "$DNSCRYPT_PID"
        wait "$DNSCRYPT_PID"
        remove_pidfile "$DNSCRYPT_PID_FILE"
        DNSCRYPT_PID=""
        [ "$STOP_REQUESTED" -eq 1 ] && break
        sleep 5
    done
}

main "$@"
