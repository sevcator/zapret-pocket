#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

STOP_REQUESTED=0
DNSCRYPT_PID=""

setup_firewall() {
    ensure_dnscrypt_firewall_base

    if iptables_supported iptables nat; then
        for proto in udp tcp; do
            for dport in 53 853; do
                append_unique_rule iptables nat "$CHAIN_DNSCRYPT_REDIRECT" -p "$proto" --dport "$dport" -j DNAT --to-destination 127.0.0.1:"$DNSCRYPT_PORT"
            done
        done
    fi

    if iptables_supported ip6tables filter; then
        append_unique_rule ip6tables filter "$CHAIN_DNSCRYPT_OUTPUT" -j DROP
        append_unique_rule ip6tables filter "$CHAIN_DNSCRYPT_FORWARD" -j DROP
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

    [ -x "$DNSCRYPT_DIR/dnscrypt-proxy" ] || {
        echo "! dnscrypt-proxy not found" >&2
        exit 1
    }

    write_pidfile "$DNSCRYPT_SUP_PID_FILE" "$$"
    trap on_signal INT TERM
    trap cleanup_runtime EXIT

    apply_dnscrypt_runtime_tweaks
    setup_firewall

    while [ "$STOP_REQUESTED" -eq 0 ]; do
        "$DNSCRYPT_DIR/dnscrypt-proxy" >/dev/null 2>&1 &
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
