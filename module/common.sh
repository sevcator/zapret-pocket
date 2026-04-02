#!/system/bin/sh

MODPATH="${MODPATH:-/data/adb/modules/zapret}"
CONFIG_DIR="${CONFIG_DIR:-$MODPATH/config}"
LIST_DIR="${LIST_DIR:-$MODPATH/list}"
LEGACY_LIST_DIR="${LEGACY_LIST_DIR:-$MODPATH/lists}"
IPSET_DIR="${IPSET_DIR:-$MODPATH/ipset}"
STRATEGY_DIR="${STRATEGY_DIR:-$MODPATH/zapret}"
LEGACY_STRATEGY_DIR="${LEGACY_STRATEGY_DIR:-$MODPATH/strategy}"
LEGACY_STRATEGIES_DIR="${LEGACY_STRATEGIES_DIR:-$MODPATH/strategies}"
DNSCRYPT_DIR="${DNSCRYPT_DIR:-$MODPATH/dnscrypt}"
FAKE_DIR="${FAKE_DIR:-$MODPATH/fake}"
BIN_DIR="${BIN_DIR:-$MODPATH/bin}"
RUN_DIR="${RUN_DIR:-$MODPATH/.run}"
STATE_DIR="${STATE_DIR:-$RUN_DIR/state}"
CURLPATH="${CURLPATH:-$MODPATH/curl}"
DNSCRYPT_PORT="${DNSCRYPT_PORT:-5253}"

DEBUG_FILE="$CONFIG_DIR/debug"
DEBUG_LOG="$RUN_DIR/debug.log"
BYPASS_CALLS_FILE="$CONFIG_DIR/bypass-calls"
CURRENT_STRATEGY_FILE="$CONFIG_DIR/current-strategy"
IPSET_FILTER_STATE="$CONFIG_DIR/ipset-filter"
LIST_GENERAL_LINK="$CONFIG_DIR/list-general-link"
LIST_GENERAL_LINK_LEGACY="$CONFIG_DIR/custom-list-general-url"
DNSCRYPT_BLOCKED_NAMES_LINK="$CONFIG_DIR/dnscrypt-blocked-names-link"
DNSCRYPT_BLOCKED_NAMES_LINK_LEGACY="$CONFIG_DIR/custom-blocked-names-url"
DNSCRYPT_CLOAKING_LINK="$CONFIG_DIR/dnscrypt-cloaking-rules-link"
DNSCRYPT_CLOAKING_LINK_LEGACY="$CONFIG_DIR/custom-cloaking-rules-url"
BYPASS_CALLS_LEGACY_FILE="$CONFIG_DIR/bypass-discord"
DEBUG_LOG_LEGACY="$CONFIG_DIR/debug.log"

ZAPRET_PID_FILE="$RUN_DIR/zapret.pid"
NFQWS_PID_FILE="$RUN_DIR/nfqws.pid"
DNSCRYPT_SUP_PID_FILE="$RUN_DIR/dnscrypt-supervisor.pid"
DNSCRYPT_PID_FILE="$RUN_DIR/dnscrypt.pid"

CHAIN_ZAPRET_POST="ZAPRET_POST"
CHAIN_ZAPRET_PRE="ZAPRET_PRE"
CHAIN_DNSCRYPT_REDIRECT="ZAPRET_DNS_REDIRECT"
CHAIN_DNSCRYPT_OUTPUT="ZAPRET_DNS_OUTPUT"
CHAIN_DNSCRYPT_FORWARD="ZAPRET_DNS_FORWARD"

set_default_file() {
    target="$1"
    value="$2"
    if [ ! -e "$target" ]; then
        mkdir -p "$(dirname "$target")"
        printf '%s\n' "$value" > "$target"
    fi
}

config_value() {
    file="$1"
    default_value="$2"
    if [ -f "$file" ]; then
        cat "$file" 2>/dev/null
        return 0
    fi
    printf '%s\n' "$default_value"
}

config_enabled() {
    value="$(config_value "$1" "$2" | tr '[:upper:]' '[:lower:]')"
    case "$value" in
        1|true|yes|on) return 0 ;;
        *) return 1 ;;
    esac
}

copy_tree_if_needed() {
    src="$1"
    dst="$2"
    [ -e "$src" ] || return 0
    mkdir -p "$dst"
    cp -af "$src"/. "$dst"/ 2>/dev/null || true
}

migrate_file_if_missing() {
    src="$1"
    dst="$2"
    [ -f "$src" ] || return 0
    mkdir -p "$(dirname "$dst")"
    if [ ! -e "$dst" ]; then
        mv "$src" "$dst"
        return 0
    fi
    rm -f "$src"
}

cleanup_deprecated_layout() {
    rm -f \
        "$LIST_DIR/custom.txt" \
        "$LIST_DIR/exclude.txt" \
        "$MODPATH/ipset/custom.txt" \
        "$MODPATH/ipset/exclude.txt" \
        "$DNSCRYPT_DIR/custom-cloaking-rules.txt" \
        "$DNSCRYPT_DIR/custom-blocked-names.txt" \
        "$DNSCRYPT_DIR/custom-blocked-ips.txt" \
        "$DNSCRYPT_DIR/custom-allowed-names.txt" \
        "$DNSCRYPT_DIR/custom-allowed-ips.txt" \
        "$CONFIG_DIR/dnscrypt-rules-fix" \
        "$CONFIG_DIR/disable-private-dns" \
        "$CONFIG_DIR/disable-tether-offload" \
        "$CONFIG_DIR/disable-ipv6" \
        "$CONFIG_DIR/relax-network" \
        "$CONFIG_DIR/install-vpnhotspot"
}

migrate_legacy_config() {
    migrate_file_if_missing "$BYPASS_CALLS_LEGACY_FILE" "$BYPASS_CALLS_FILE"
    migrate_file_if_missing "$LIST_GENERAL_LINK_LEGACY" "$LIST_GENERAL_LINK"
    migrate_file_if_missing "$DNSCRYPT_BLOCKED_NAMES_LINK_LEGACY" "$DNSCRYPT_BLOCKED_NAMES_LINK"
    migrate_file_if_missing "$DNSCRYPT_CLOAKING_LINK_LEGACY" "$DNSCRYPT_CLOAKING_LINK"

    if [ -f "$DEBUG_LOG_LEGACY" ]; then
        mkdir -p "$(dirname "$DEBUG_LOG")"
        if [ ! -e "$DEBUG_LOG" ]; then
            mv "$DEBUG_LOG_LEGACY" "$DEBUG_LOG"
        else
            rm -f "$DEBUG_LOG_LEGACY"
        fi
    fi

    cleanup_deprecated_layout
}

ensure_layout() {
    mkdir -p "$CONFIG_DIR" "$LIST_DIR" "$IPSET_DIR" "$STRATEGY_DIR" "$DNSCRYPT_DIR" "$FAKE_DIR" "$BIN_DIR" "$RUN_DIR" "$STATE_DIR"

    if [ -d "$LEGACY_LIST_DIR" ]; then
        copy_tree_if_needed "$LEGACY_LIST_DIR" "$LIST_DIR"
    fi

    if [ -d "$LEGACY_STRATEGY_DIR" ]; then
        copy_tree_if_needed "$LEGACY_STRATEGY_DIR" "$STRATEGY_DIR"
    fi

    if [ -d "$LEGACY_STRATEGIES_DIR" ]; then
        copy_tree_if_needed "$LEGACY_STRATEGIES_DIR" "$STRATEGY_DIR"
    fi
}

ensure_default_config() {
    ensure_layout
    migrate_legacy_config
    set_default_file "$DEBUG_FILE" "0"
    set_default_file "$BYPASS_CALLS_FILE" "0"
    set_default_file "$CURRENT_STRATEGY_FILE" "general"
    set_default_file "$LIST_DIR/list-general-user.txt" ""
    set_default_file "$LIST_DIR/list-exclude-user.txt" ""
    set_default_file "$IPSET_DIR/ipset-exclude.txt" ""
    set_default_file "$IPSET_DIR/ipset-exclude-user.txt" ""
    cleanup_deprecated_layout
}

pid_is_running() {
    [ -n "$1" ] && kill -0 "$1" 2>/dev/null
}

pidfile_get() {
    file="$1"
    [ -f "$file" ] || return 1
    pid="$(cat "$file" 2>/dev/null)"
    [ -n "$pid" ] || return 1
    printf '%s\n' "$pid"
}

pidfile_is_running() {
    pid="$(pidfile_get "$1" 2>/dev/null)" || return 1
    pid_is_running "$pid"
}

write_pidfile() {
    file="$1"
    pid="$2"
    mkdir -p "$(dirname "$file")"
    printf '%s\n' "$pid" > "$file"
}

remove_pidfile() {
    rm -f "$1"
}

wait_for_exit() {
    pid="$1"
    retries="${2:-20}"
    while [ "$retries" -gt 0 ]; do
        pid_is_running "$pid" || return 0
        sleep 1
        retries=$((retries - 1))
    done
    return 1
}

terminate_pidfile() {
    file="$1"
    signal="${2:-TERM}"
    pid="$(pidfile_get "$file" 2>/dev/null)" || return 0
    kill "-$signal" "$pid" 2>/dev/null || true
}

terminate_pidfile_gracefully() {
    file="$1"
    pid="$(pidfile_get "$file" 2>/dev/null)" || return 0
    kill -TERM "$pid" 2>/dev/null || true
    if ! wait_for_exit "$pid" 10; then
        kill -KILL "$pid" 2>/dev/null || true
        wait_for_exit "$pid" 5 || true
    fi
    remove_pidfile "$file"
}

service_is_running() {
    pidfile_is_running "$ZAPRET_PID_FILE" && return 0
    pgrep -f "$STRATEGY_DIR/zapret.sh" >/dev/null 2>&1
}

dnscrypt_supervisor_is_running() {
    pidfile_is_running "$DNSCRYPT_SUP_PID_FILE" && return 0
    pgrep -f "$MODPATH/dnscrypt/dnscrypt.sh" >/dev/null 2>&1
}

dnscrypt_is_running() {
    pidfile_is_running "$DNSCRYPT_PID_FILE" && return 0
    pgrep -x dnscrypt-proxy >/dev/null 2>&1
}

iptables_supported() {
    tool="$1"
    table="$2"
    command -v "$tool" >/dev/null 2>&1 || return 1
    "$tool" -t "$table" -S >/dev/null 2>&1
}

append_unique_rule() {
    tool="$1"
    table="$2"
    chain="$3"
    shift 3
    "$tool" -t "$table" -C "$chain" "$@" >/dev/null 2>&1 || "$tool" -t "$table" -A "$chain" "$@" >/dev/null 2>&1
}

insert_unique_jump() {
    tool="$1"
    table="$2"
    parent="$3"
    chain="$4"
    "$tool" -t "$table" -C "$parent" -j "$chain" >/dev/null 2>&1 || "$tool" -t "$table" -I "$parent" -j "$chain" >/dev/null 2>&1
}

ensure_chain() {
    tool="$1"
    table="$2"
    chain="$3"
    if ! iptables_supported "$tool" "$table"; then
        return 1
    fi
    "$tool" -t "$table" -N "$chain" >/dev/null 2>&1 || "$tool" -t "$table" -F "$chain" >/dev/null 2>&1
    return 0
}

remove_chain() {
    tool="$1"
    table="$2"
    parent="$3"
    chain="$4"
    if ! iptables_supported "$tool" "$table"; then
        return 0
    fi
    while "$tool" -t "$table" -D "$parent" -j "$chain" >/dev/null 2>&1; do :; done
    "$tool" -t "$table" -F "$chain" >/dev/null 2>&1 || true
    "$tool" -t "$table" -X "$chain" >/dev/null 2>&1 || true
}

ensure_zapret_firewall_base() {
    ensure_chain iptables mangle "$CHAIN_ZAPRET_POST" || return 0
    ensure_chain iptables mangle "$CHAIN_ZAPRET_PRE" || return 0
    insert_unique_jump iptables mangle POSTROUTING "$CHAIN_ZAPRET_POST"
    insert_unique_jump iptables mangle PREROUTING "$CHAIN_ZAPRET_PRE"

    if iptables_supported ip6tables mangle; then
        ensure_chain ip6tables mangle "$CHAIN_ZAPRET_POST" || true
        ensure_chain ip6tables mangle "$CHAIN_ZAPRET_PRE" || true
        insert_unique_jump ip6tables mangle POSTROUTING "$CHAIN_ZAPRET_POST"
        insert_unique_jump ip6tables mangle PREROUTING "$CHAIN_ZAPRET_PRE"
    fi
}

cleanup_zapret_firewall() {
    remove_chain iptables mangle POSTROUTING "$CHAIN_ZAPRET_POST"
    remove_chain iptables mangle PREROUTING "$CHAIN_ZAPRET_PRE"
    remove_chain ip6tables mangle POSTROUTING "$CHAIN_ZAPRET_POST"
    remove_chain ip6tables mangle PREROUTING "$CHAIN_ZAPRET_PRE"
}

ensure_dnscrypt_firewall_base() {
    if iptables_supported iptables nat; then
        ensure_chain iptables nat "$CHAIN_DNSCRYPT_REDIRECT" || true
        insert_unique_jump iptables nat PREROUTING "$CHAIN_DNSCRYPT_REDIRECT"
        insert_unique_jump iptables nat OUTPUT "$CHAIN_DNSCRYPT_REDIRECT"
    fi

    if iptables_supported iptables filter; then
        ensure_chain iptables filter "$CHAIN_DNSCRYPT_OUTPUT" || true
        ensure_chain iptables filter "$CHAIN_DNSCRYPT_FORWARD" || true
        insert_unique_jump iptables filter OUTPUT "$CHAIN_DNSCRYPT_OUTPUT"
        insert_unique_jump iptables filter FORWARD "$CHAIN_DNSCRYPT_FORWARD"
    fi

    if iptables_supported ip6tables filter; then
        ensure_chain ip6tables filter "$CHAIN_DNSCRYPT_OUTPUT" || true
        ensure_chain ip6tables filter "$CHAIN_DNSCRYPT_FORWARD" || true
        insert_unique_jump ip6tables filter OUTPUT "$CHAIN_DNSCRYPT_OUTPUT"
        insert_unique_jump ip6tables filter FORWARD "$CHAIN_DNSCRYPT_FORWARD"
    fi
}

cleanup_dnscrypt_firewall() {
    remove_chain iptables nat PREROUTING "$CHAIN_DNSCRYPT_REDIRECT"
    remove_chain iptables nat OUTPUT "$CHAIN_DNSCRYPT_REDIRECT"
    remove_chain iptables filter OUTPUT "$CHAIN_DNSCRYPT_OUTPUT"
    remove_chain iptables filter FORWARD "$CHAIN_DNSCRYPT_FORWARD"
    remove_chain ip6tables filter OUTPUT "$CHAIN_DNSCRYPT_OUTPUT"
    remove_chain ip6tables filter FORWARD "$CHAIN_DNSCRYPT_FORWARD"
}

cleanup_all_firewall() {
    cleanup_zapret_firewall
    cleanup_dnscrypt_firewall
}

sysctl_state_file() {
    printf '%s/%s.state\n' "$STATE_DIR" "$1"
}

remember_sysctl_value() {
    state_name="$1"
    key="$2"
    state_file="$(sysctl_state_file "$state_name")"
    [ -f "$state_file" ] && return 0
    current="$(sysctl -n "$key" 2>/dev/null)" || return 1
    printf '%s\n' "$current" > "$state_file"
}

apply_managed_sysctl() {
    state_name="$1"
    key="$2"
    value="$3"
    remember_sysctl_value "$state_name" "$key" || return 1
    sysctl -w "$key=$value" >/dev/null 2>&1
}

restore_managed_sysctl() {
    state_name="$1"
    key="$2"
    state_file="$(sysctl_state_file "$state_name")"
    [ -f "$state_file" ] || return 0
    value="$(cat "$state_file" 2>/dev/null)"
    [ -n "$value" ] && sysctl -w "$key=$value" >/dev/null 2>&1
    rm -f "$state_file"
}

apply_optional_network_tweaks() {
    return 0
}

restore_optional_network_tweaks() {
    return 0
}

apply_dnscrypt_runtime_tweaks() {
    apply_managed_sysctl "route_localnet" "net.ipv4.conf.all.route_localnet" "1" || true
}

restore_dnscrypt_runtime_tweaks() {
    restore_managed_sysctl "route_localnet" "net.ipv4.conf.all.route_localnet"
}

stop_module_service() {
    terminate_pidfile_gracefully "$ZAPRET_PID_FILE"
    terminate_pidfile_gracefully "$NFQWS_PID_FILE"
    terminate_pidfile_gracefully "$DNSCRYPT_SUP_PID_FILE"
    terminate_pidfile_gracefully "$DNSCRYPT_PID_FILE"

    pkill -TERM -f "$STRATEGY_DIR/zapret.sh" >/dev/null 2>&1 || true
    pkill -TERM -f "$MODPATH/dnscrypt/dnscrypt.sh" >/dev/null 2>&1 || true
    pkill -TERM -x nfqws >/dev/null 2>&1 || true
    pkill -TERM -x dnscrypt-proxy >/dev/null 2>&1 || true
    sleep 1
    pkill -KILL -f "$STRATEGY_DIR/zapret.sh" >/dev/null 2>&1 || true
    pkill -KILL -f "$MODPATH/dnscrypt/dnscrypt.sh" >/dev/null 2>&1 || true
    pkill -KILL -x nfqws >/dev/null 2>&1 || true
    pkill -KILL -x dnscrypt-proxy >/dev/null 2>&1 || true

    cleanup_all_firewall
    restore_dnscrypt_runtime_tweaks
    restore_optional_network_tweaks

    remove_pidfile "$ZAPRET_PID_FILE"
    remove_pidfile "$NFQWS_PID_FILE"
    remove_pidfile "$DNSCRYPT_SUP_PID_FILE"
    remove_pidfile "$DNSCRYPT_PID_FILE"
    return 0
}
