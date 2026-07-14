#!/system/bin/sh

MODPATH="${MODPATH:-/data/adb/modules/zapret}"
CONFIG_DIR="${CONFIG_DIR:-$MODPATH/config}"
LIST_DIR="${LIST_DIR:-$MODPATH/list}"
LEGACY_LIST_DIR="${LEGACY_LIST_DIR:-$MODPATH/lists}"
IPSET_DIR="${IPSET_DIR:-$MODPATH/list}"
ZAPRET_DIR="${ZAPRET_DIR:-$MODPATH/zapret}"
LUA_DIR="${LUA_DIR:-$MODPATH/lua}"
STRATEGY_DIR="${STRATEGY_DIR:-$MODPATH/strategy}"
LEGACY_STRATEGY_DIR="${LEGACY_STRATEGY_DIR:-$MODPATH/strategies}"
LEGACY_ZAPRET_STRATEGY_DIR="${LEGACY_ZAPRET_STRATEGY_DIR:-$ZAPRET_DIR}"
DNSCRYPT_DIR="${DNSCRYPT_DIR:-$MODPATH/dnscrypt}"
SERVICE_DIR="${SERVICE_DIR:-$MODPATH/.service}"
RUN_DIR="${RUN_DIR:-$SERVICE_DIR}"
STATE_DIR="${STATE_DIR:-$SERVICE_DIR/state}"
CURLPATH="${CURLPATH:-$MODPATH/curl}"
DNSCRYPT_PORT="${DNSCRYPT_PORT:-5253}"

DEBUG_FILE="$CONFIG_DIR/debug"
DEBUG_LOG="$RUN_DIR/debug.log"
BYPASS_CALLS_FILE="$CONFIG_DIR/bypass-calls"
CURRENT_STRATEGY_FILE="$CONFIG_DIR/current-strategy"
IPSET_FILTER_STATE="$CONFIG_DIR/ipset-filter"
INTERFACE_ONLY_FILE="$CONFIG_DIR/interface-only"
IPSET_LINK_FILE="$CONFIG_DIR/ipset-link"
LIST_GENERAL_USER_FILE="$LIST_DIR/list-general-user.txt"
LIST_EXCLUDE_USER_FILE="$LIST_DIR/list-exclude-user.txt"
IPSET_ALL_USER_FILE="$IPSET_DIR/ipset-all-user.txt"
IPSET_EXCLUDE_FILE="$IPSET_DIR/ipset-exclude.txt"
IPSET_EXCLUDE_USER_FILE="$IPSET_DIR/ipset-exclude-user.txt"
LIST_GENERAL_LINK="$CONFIG_DIR/list-general-link"
LIST_GENERAL_LINK_LEGACY="$CONFIG_DIR/custom-list-general-url"
DNSCRYPT_BLOCKED_NAMES_LINK="$CONFIG_DIR/dnscrypt-blocked-names-link"
DNSCRYPT_BLOCKED_NAMES_LINK_LEGACY="$CONFIG_DIR/custom-blocked-names-url"
DNSCRYPT_BLOCKED_IPS_LINK="$CONFIG_DIR/dnscrypt-blocked-ips-link"
DNSCRYPT_CLOAKING_LINK="$CONFIG_DIR/dnscrypt-cloaking-rules-link"
DNSCRYPT_CLOAKING_LINK_LEGACY="$CONFIG_DIR/custom-cloaking-rules-url"
# User overlay files: their rules are appended to the refreshed dnscrypt base files at
# every start, so user customizations survive base-list updates (refresh_linked_lists ->
# apply_dnscrypt_user_overlays). Preserved across module updates by customize.sh.
DNSCRYPT_CLOAKING_USER_FILE="$DNSCRYPT_DIR/cloaking-rules-user.txt"
DNSCRYPT_BLOCKED_NAMES_USER_FILE="$DNSCRYPT_DIR/blocked-names-user.txt"
DNSCRYPT_BLOCKED_IPS_USER_FILE="$DNSCRYPT_DIR/blocked-ips-user.txt"
TELEGRAM_BYPASS_FILE="$CONFIG_DIR/telegram-bypass"
TELEGRAM_BYPASS_SECRET_FILE="$CONFIG_DIR/telegram-bypass-secret"
TELEGRAM_BYPASS_PORT_FILE="$CONFIG_DIR/telegram-bypass-port"
TELEGRAM_BYPASS_DC_IP_FILE="$CONFIG_DIR/telegram-bypass-dc-ip"
TELEGRAM_BYPASS_CFPROXY_FILE="$CONFIG_DIR/telegram-bypass-cfproxy"
TELEGRAM_BYPASS_CFPROXY_DOMAIN_FILE="$CONFIG_DIR/telegram-bypass-cfproxy-domain"
TELEGRAM_BYPASS_CFWORKER_DOMAIN_FILE="$CONFIG_DIR/telegram-bypass-cfworker-domain"
TELEGRAM_BYPASS_VERBOSE_FILE="$CONFIG_DIR/telegram-bypass-verbose"
TELEGRAM_BYPASS_BUFKB_FILE="$CONFIG_DIR/telegram-bypass-bufkb"
TELEGRAM_BYPASS_POOL_SIZE_FILE="$CONFIG_DIR/telegram-bypass-pool-size"
TG_WS_PROXY_DIR="$MODPATH/tg-ws-proxy"
TG_WS_PROXY_PID_FILE="$RUN_DIR/tg-ws-proxy.pid"
TG_WS_PROXY_LOG_FILE="$RUN_DIR/tg-ws-proxy.log"
TERMUX_PYTHON="/data/data/com.termux/files/usr/bin/python3"
BYPASS_CALLS_LEGACY_FILE="$CONFIG_DIR/bypass-discord"
DEBUG_LOG_LEGACY="$CONFIG_DIR/debug.log"

ZAPRET_PID_FILE="$RUN_DIR/zapret.pid"
NFQWS_PID_FILE="$RUN_DIR/nfqws.pid"
DNSCRYPT_SUP_PID_FILE="$RUN_DIR/dnscrypt-supervisor.pid"
DNSCRYPT_PID_FILE="$RUN_DIR/dnscrypt.pid"

debug_enabled() {
    [ "${CLI_DEBUG:-0}" = "1" ]
}

debug_log() {
    debug_enabled || return 0
    printf '[zapret][debug] %s\n' "$*" >&2
}

boot_completed() {
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ]
}

wait_for_boot_complete() {
    while ! boot_completed; do
        sleep 2
    done
}

CHAIN_ZAPRET_POST="ZAPRET_POST"
CHAIN_ZAPRET_PRE="ZAPRET_PRE"
CHAIN_ZAPRET_QUIC="ZAPRET_QUIC"
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

copy_strategy_scripts_if_needed() {
    src="$1"
    [ -d "$src" ] || return 0
    mkdir -p "$STRATEGY_DIR"
    for file in "$src"/*.sh; do
        [ -f "$file" ] || continue
        base="${file##*/}"
        case "$base" in
            zapret.sh|make-unkillable.sh) continue ;;
        esac
        dst="$STRATEGY_DIR/$base"
        # This runs on EVERY service start (zapret.sh, dnscrypt.sh and the CLI all
        # call ensure_layout) and the strategy set is large (~340 files). Re-copying
        # all of them each time forks basename+cp per file and delayed nfqws startup
        # by tens of seconds. Use ${##} (no fork) and skip files that are already
        # present and not older than the source.
        [ -e "$dst" ] && [ ! "$file" -nt "$dst" ] && continue
        cp -af "$file" "$dst" 2>/dev/null || true
    done
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
    set -- "$LIST_DIR/custom.txt" "$LIST_DIR/exclude.txt" "$MODPATH/list/custom.txt" "$MODPATH/list/exclude.txt" "$DNSCRYPT_DIR/custom-cloaking-rules.txt" "$DNSCRYPT_DIR/custom-blocked-names.txt" "$DNSCRYPT_DIR/custom-blocked-ips.txt" "$DNSCRYPT_DIR/custom-allowed-names.txt" "$DNSCRYPT_DIR/custom-allowed-ips.txt" "$CONFIG_DIR/dnscrypt-rules-fix" "$CONFIG_DIR/disable-private-dns" "$CONFIG_DIR/disable-tether-offload" "$CONFIG_DIR/disable-ipv6" "$CONFIG_DIR/relax-network" "$CONFIG_DIR/install-vpnhotspot"
    for path in "$@"; do
        rm -f "$path"
    done

    for path in "$LIST_DIR"/*.bak "$LIST_DIR"/*.backup; do
        [ -e "$path" ] || continue
        rm -f "$path"
    done
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
    mkdir -p "$CONFIG_DIR" "$LIST_DIR" "$IPSET_DIR" "$ZAPRET_DIR" "$LUA_DIR" "$STRATEGY_DIR" "$DNSCRYPT_DIR" "$SERVICE_DIR" "$STATE_DIR"

    if [ -d "$MODPATH/.run" ] && [ "$MODPATH/.run" != "$SERVICE_DIR" ]; then
        copy_tree_if_needed "$MODPATH/.run" "$SERVICE_DIR"
    fi

    if [ -d "$LEGACY_LIST_DIR" ]; then
        copy_tree_if_needed "$LEGACY_LIST_DIR" "$LIST_DIR"
    fi

    if [ -d "$LEGACY_ZAPRET_STRATEGY_DIR" ]; then
        copy_strategy_scripts_if_needed "$LEGACY_ZAPRET_STRATEGY_DIR"
    fi

    if [ -d "$LEGACY_STRATEGY_DIR" ]; then
        copy_strategy_scripts_if_needed "$LEGACY_STRATEGY_DIR"
    fi
}

ensure_default_config() {
    ensure_layout
    migrate_legacy_config
    set_default_file "$DEBUG_FILE" "0"
    set_default_file "$BYPASS_CALLS_FILE" "0"
    set_default_file "$CURRENT_STRATEGY_FILE" "general"
    set_default_file "$LIST_GENERAL_USER_FILE" ""
    set_default_file "$LIST_EXCLUDE_USER_FILE" ""
    set_default_file "$IPSET_ALL_USER_FILE" ""
    set_default_file "$IPSET_EXCLUDE_FILE" ""
    set_default_file "$IPSET_EXCLUDE_USER_FILE" ""
    ensure_telegram_bypass_defaults
    cleanup_deprecated_layout
}

ensure_runtime_files() {
    for file in "$LIST_GENERAL_USER_FILE" \
                "$LIST_EXCLUDE_USER_FILE" \
                "$IPSET_ALL_USER_FILE" \
                "$IPSET_EXCLUDE_FILE" \
                "$IPSET_EXCLUDE_USER_FILE" \
                "$DNSCRYPT_DIR/cloaking-rules.txt" \
                "$DNSCRYPT_DIR/blocked-names.txt" \
                "$DNSCRYPT_DIR/blocked-ips.txt" \
                "$DNSCRYPT_CLOAKING_USER_FILE" \
                "$DNSCRYPT_BLOCKED_NAMES_USER_FILE" \
                "$DNSCRYPT_BLOCKED_IPS_USER_FILE"; do
        [ -e "$file" ] || : > "$file"
    done
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
    pgrep -f "$ZAPRET_DIR/zapret.sh" >/dev/null 2>&1
}

dnscrypt_script_path() {
    printf '%s\n' "${DNSCRYPT_DIR:-$MODPATH/dnscrypt}/dnscrypt.sh"
}

dnscrypt_supervisor_is_running() {
    _dnscrypt_script="$(dnscrypt_script_path)"
    pidfile_is_running "$DNSCRYPT_SUP_PID_FILE" && return 0
    pgrep -f "$_dnscrypt_script" >/dev/null 2>&1 && return 0
    [ "$_dnscrypt_script" = "$MODPATH/dnscrypt/dnscrypt.sh" ] || pgrep -f "$MODPATH/dnscrypt/dnscrypt.sh" >/dev/null 2>&1
}

dnscrypt_is_running() {
    pidfile_is_running "$DNSCRYPT_PID_FILE" && return 0
    pgrep -x dnscrypt-proxy >/dev/null 2>&1
}

nfqws_is_running() {
    pidfile_is_running "$NFQWS_PID_FILE" && return 0
    pgrep -x nfqws >/dev/null 2>&1 && return 0
    pgrep -x nfqws2 >/dev/null 2>&1
}

# iptables and ip6tables share one kernel lock (xtables). Android's netd and the
# second zapret daemon (dnscrypt.sh) modify rules at the same time, so WITHOUT -w
# our rule installs intermittently fail ("another app is holding the xtables lock")
# — and because every call is silenced with 2>/dev/null the failure is invisible:
# the module looks like it started while no traffic is actually queued (the classic
# "starts but nothing changes"). -w makes iptables wait for the lock. Probed once,
# because very old binaries accept -w with no seconds argument.
# Must always be expanded UNQUOTED ($IPT_LOCK_WAIT, never "$IPT_LOCK_WAIT") so it
# field-splits into the two args `-w 5` (or nothing). Quoting it would pass the
# single literal "-w 5" to iptables and error.
IPT_LOCK_WAIT=""
_IPT_WAIT_PROBED=""
ensure_ipt_lock_wait() {
    [ -n "$_IPT_WAIT_PROBED" ] && return 0
    _IPT_WAIT_PROBED=1
    # `-S` is read-only and returns immediately; this only tests whether the binary
    # accepts the `-w <seconds>` syntax (every iptables that has the xtables lock,
    # i.e. >= 1.6.0, does). If not, fall back to lock-less calls (the old behavior)
    # rather than a bare `-w`, which on ancient binaries means "wait forever".
    if iptables -w 5 -t filter -S >/dev/null 2>&1; then
        IPT_LOCK_WAIT="-w 5"
    fi
}

iptables_supported() {
    tool="$1"
    table="$2"
    command -v "$tool" >/dev/null 2>&1 || return 1
    ensure_ipt_lock_wait
    "$tool" $IPT_LOCK_WAIT -t "$table" -S >/dev/null 2>&1
}

append_unique_rule() {
    tool="$1"
    table="$2"
    chain="$3"
    shift 3
    ensure_ipt_lock_wait
    "$tool" $IPT_LOCK_WAIT -t "$table" -C "$chain" "$@" >/dev/null 2>&1 || "$tool" $IPT_LOCK_WAIT -t "$table" -A "$chain" "$@" >/dev/null 2>&1
}

insert_unique_jump() {
    tool="$1"
    table="$2"
    parent="$3"
    chain="$4"
    ensure_ipt_lock_wait
    "$tool" $IPT_LOCK_WAIT -t "$table" -C "$parent" -j "$chain" >/dev/null 2>&1 || "$tool" $IPT_LOCK_WAIT -t "$table" -I "$parent" -j "$chain" >/dev/null 2>&1
}

ensure_chain() {
    tool="$1"
    table="$2"
    chain="$3"
    if ! iptables_supported "$tool" "$table"; then
        return 1
    fi
    "$tool" $IPT_LOCK_WAIT -t "$table" -N "$chain" >/dev/null 2>&1 || "$tool" $IPT_LOCK_WAIT -t "$table" -F "$chain" >/dev/null 2>&1
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
    while "$tool" $IPT_LOCK_WAIT -t "$table" -D "$parent" -j "$chain" >/dev/null 2>&1; do :; done
    "$tool" $IPT_LOCK_WAIT -t "$table" -F "$chain" >/dev/null 2>&1 || true
    "$tool" $IPT_LOCK_WAIT -t "$table" -X "$chain" >/dev/null 2>&1 || true
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
        # Redirect DNS on all chains so mobile data (PREROUTING/FORWARD) is also covered
        insert_unique_jump iptables nat PREROUTING "$CHAIN_DNSCRYPT_REDIRECT"
        insert_unique_jump iptables nat OUTPUT    "$CHAIN_DNSCRYPT_REDIRECT"
    fi

    if iptables_supported iptables filter; then
        ensure_chain iptables filter "$CHAIN_DNSCRYPT_OUTPUT"  || true
        ensure_chain iptables filter "$CHAIN_DNSCRYPT_FORWARD" || true
        insert_unique_jump iptables filter OUTPUT  "$CHAIN_DNSCRYPT_OUTPUT"
        insert_unique_jump iptables filter FORWARD "$CHAIN_DNSCRYPT_FORWARD"
    fi

    if iptables_supported ip6tables filter; then
        ensure_chain ip6tables filter "$CHAIN_DNSCRYPT_OUTPUT"  || true
        ensure_chain ip6tables filter "$CHAIN_DNSCRYPT_FORWARD" || true
        insert_unique_jump ip6tables filter OUTPUT  "$CHAIN_DNSCRYPT_OUTPUT"
        insert_unique_jump ip6tables filter FORWARD "$CHAIN_DNSCRYPT_FORWARD"
    fi
}

cleanup_dnscrypt_firewall() {
    remove_chain iptables nat PREROUTING "$CHAIN_DNSCRYPT_REDIRECT"
    remove_chain iptables nat OUTPUT     "$CHAIN_DNSCRYPT_REDIRECT"
    remove_chain iptables filter OUTPUT  "$CHAIN_DNSCRYPT_OUTPUT"
    remove_chain iptables filter FORWARD "$CHAIN_DNSCRYPT_FORWARD"
    remove_chain ip6tables filter OUTPUT  "$CHAIN_DNSCRYPT_OUTPUT"
    remove_chain ip6tables filter FORWARD "$CHAIN_DNSCRYPT_FORWARD"
}

# Resolve an Android package name to its Linux UID (for `-m owner` per-app rules).
# Multi-tier fallback so it works across roots/ROMs. Ported from ZDT-D pkg_uid.rs.
resolve_pkg_uid() {
    _rpu_pkg="$1"
    _rpu_uid="$(cmd package list packages -U 2>/dev/null | grep "^package:${_rpu_pkg} " | sed -n 's/.*uid:\([0-9][0-9]*\).*/\1/p' | head -1)"
    [ -n "$_rpu_uid" ] || _rpu_uid="$(dumpsys package "$_rpu_pkg" 2>/dev/null | grep -oE 'userId=[0-9]+' | head -1 | grep -oE '[0-9]+')"
    [ -n "$_rpu_uid" ] || _rpu_uid="$(stat -c '%u' "/data/data/${_rpu_pkg}" 2>/dev/null)"
    case "$_rpu_uid" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "$_rpu_uid" -gt 0 ] 2>/dev/null && printf '%s\n' "$_rpu_uid"
}

# QUIC (HTTP/3 over UDP 443) is far harder to desync reliably than TCP on many RU
# networks, so forcing apps off QUIC onto the TCP path our desync DOES bypass is
# often the difference between an app working or not. REJECT (icmp[6] port-unreachable)
# makes the app fall back to TCP instantly instead of waiting out a multi-second QUIC
# timeout (DROP would stall). Controlled by config/quic-block (idea from ZDT-D
# blockedquic.rs): "off"/absent = nothing; "global"/"1" = block all udp/443;
# otherwise = treated as a space/comma list of package names blocked by UID.
apply_quic_block() {
    _qb="$(config_value "$CONFIG_DIR/quic-block" "off")"
    case "$_qb" in
        off|0|"") return 0 ;;
    esac
    iptables_supported iptables filter && { ensure_chain iptables filter "$CHAIN_ZAPRET_QUIC"; insert_unique_jump iptables filter OUTPUT "$CHAIN_ZAPRET_QUIC"; }
    iptables_supported ip6tables filter && { ensure_chain ip6tables filter "$CHAIN_ZAPRET_QUIC"; insert_unique_jump ip6tables filter OUTPUT "$CHAIN_ZAPRET_QUIC"; }
    case "$_qb" in
        global|1)
            append_unique_rule iptables filter "$CHAIN_ZAPRET_QUIC" -p udp --dport 443 -j REJECT --reject-with icmp-port-unreachable
            append_unique_rule ip6tables filter "$CHAIN_ZAPRET_QUIC" -p udp --dport 443 -j REJECT --reject-with icmp6-port-unreachable
            ;;
        *)
            for _pkg in $(printf '%s' "$_qb" | tr ',' ' '); do
                _uid="$(resolve_pkg_uid "$_pkg")" || continue
                append_unique_rule iptables filter "$CHAIN_ZAPRET_QUIC" -p udp --dport 443 -m owner --uid-owner "$_uid" -j REJECT --reject-with icmp-port-unreachable
                append_unique_rule ip6tables filter "$CHAIN_ZAPRET_QUIC" -p udp --dport 443 -m owner --uid-owner "$_uid" -j REJECT --reject-with icmp6-port-unreachable
            done
            ;;
    esac
    return 0
}

cleanup_quic_block() {
    remove_chain iptables filter OUTPUT "$CHAIN_ZAPRET_QUIC"
    remove_chain ip6tables filter OUTPUT "$CHAIN_ZAPRET_QUIC"
}

cleanup_all_firewall() {
    cleanup_zapret_firewall
    cleanup_dnscrypt_firewall
    cleanup_quic_block
}

sysctl_state_file() {
    printf '%s/%s.state\n' "$STATE_DIR" "$1"
}

# sysctl read/write that does NOT depend on a `sysctl` binary being reachable on
# PATH. A plain `su` shell often lacks the Magisk busybox dir on its PATH, so an
# external sysctl may be unreachable when the CLI is run by hand. Writing
# /proc/sys/... directly is the universal, fork-free method that behaves
# identically under mksh, busybox ash and toybox; the sysctl binary is only a
# last-resort fallback. This matters most for route_localnet — without it the DNS
# DNAT to 127.0.0.1 is martian-dropped and resolution breaks entirely.
sysctl_proc_path() {
    # net.ipv4.conf.all.route_localnet -> /proc/sys/net/ipv4/conf/all/route_localnet
    printf '/proc/sys/%s\n' "$(printf '%s' "$1" | tr '.' '/')"
}

read_sysctl_value() {
    _rsv_path="$(sysctl_proc_path "$1")"
    if [ -r "$_rsv_path" ]; then
        cat "$_rsv_path" 2>/dev/null
        return 0
    fi
    sysctl -n "$1" 2>/dev/null
}

write_sysctl_value() {
    _wsv_path="$(sysctl_proc_path "$1")"
    if [ -w "$_wsv_path" ]; then
        printf '%s\n' "$2" > "$_wsv_path" 2>/dev/null && return 0
    fi
    sysctl -w "$1=$2" >/dev/null 2>&1
}

remember_sysctl_value() {
    state_name="$1"
    key="$2"
    state_file="$(sysctl_state_file "$state_name")"
    [ -f "$state_file" ] && return 0
    current="$(read_sysctl_value "$key")"
    [ -n "$current" ] || return 1
    printf '%s\n' "$current" > "$state_file"
}

apply_managed_sysctl() {
    state_name="$1"
    key="$2"
    value="$3"
    remember_sysctl_value "$state_name" "$key" || return 1
    write_sysctl_value "$key" "$value"
}

restore_managed_sysctl() {
    state_name="$1"
    key="$2"
    state_file="$(sysctl_state_file "$state_name")"
    [ -f "$state_file" ] || return 0
    value="$(cat "$state_file" 2>/dev/null)"
    [ -n "$value" ] && write_sysctl_value "$key" "$value"
    rm -f "$state_file"
}

# Network tuning that improves DPI-bypass reliability and throughput (ported from
# ZDT-D's service.sh). fq_codel + BBR cut bufferbloat so nfqws packet-injection
# timing stays accurate; bigger socket buffers fix throughput stalls; tcp_mtu_probing
# survives PMTU black holes that desync/splits can trigger; tcp_slow_start_after_idle=0
# avoids the post-idle/Doze throughput crater that kills the first connections; a
# bigger conntrack table avoids silent DROPs that large hostlists/ipsets cause. Every
# write is a no-op where the knob is absent, and originals are remembered + restored
# on stop. NOTE: nf_conntrack_tcp_be_liberal stays at the module's deliberate 1
# (set in service.sh) — do not force it to 0.
apply_optional_network_tweaks() {
    case "$(read_sysctl_value net.ipv4.tcp_available_congestion_control)" in
        *bbr*) apply_managed_sysctl "cc" "net.ipv4.tcp_congestion_control" "bbr" || true ;;
    esac
    for _q in fq_codel fq codel; do
        apply_managed_sysctl "qdisc" "net.core.default_qdisc" "$_q" || true
        [ "$(read_sysctl_value net.core.default_qdisc)" = "$_q" ] && break
    done
    apply_managed_sysctl "rmem_max" "net.core.rmem_max" "4194304" || true
    apply_managed_sysctl "wmem_max" "net.core.wmem_max" "4194304" || true
    apply_managed_sysctl "backlog" "net.core.netdev_max_backlog" "4096" || true
    apply_managed_sysctl "mtu_probing" "net.ipv4.tcp_mtu_probing" "1" || true
    apply_managed_sysctl "ss_idle" "net.ipv4.tcp_slow_start_after_idle" "0" || true
    apply_managed_sysctl "ct_max" "net.netfilter.nf_conntrack_max" "262144" || true
    return 0
}

restore_optional_network_tweaks() {
    restore_managed_sysctl "cc" "net.ipv4.tcp_congestion_control"
    restore_managed_sysctl "qdisc" "net.core.default_qdisc"
    restore_managed_sysctl "rmem_max" "net.core.rmem_max"
    restore_managed_sysctl "wmem_max" "net.core.wmem_max"
    restore_managed_sysctl "backlog" "net.core.netdev_max_backlog"
    restore_managed_sysctl "mtu_probing" "net.ipv4.tcp_mtu_probing"
    restore_managed_sysctl "ss_idle" "net.ipv4.tcp_slow_start_after_idle"
    restore_managed_sysctl "ct_max" "net.netfilter.nf_conntrack_max"
    return 0
}

# Boot race (ported from ZDT-D internet_wait): Magisk service.sh runs during the
# boot animation, before the network stack / default route / conntrack are ready, so
# iptables rules and nfqws started too early are silently lost. Probe a few known
# TCP:443 endpoints (not ICMP — captive portals and RU networks drop it) and proceed
# once one answers, or after ~2 min so boot never hangs. Always returns 0.
wait_for_internet() {
    _wfi=0
    while [ "$_wfi" -lt 120 ]; do
        for _wfi_ip in 1.1.1.1 8.8.8.8 9.9.9.9; do
            if timeout 2 nc "$_wfi_ip" 443 </dev/null >/dev/null 2>&1; then
                return 0
            fi
        done
        sleep 3
        _wfi=$((_wfi + 3))
    done
    return 0
}

apply_dnscrypt_runtime_tweaks() {
    apply_managed_sysctl "route_localnet" "net.ipv4.conf.all.route_localnet" "1" || true
}

restore_dnscrypt_runtime_tweaks() {
    restore_managed_sysctl "route_localnet" "net.ipv4.conf.all.route_localnet"
}

read_link_file() {
    for file in "$@"; do
        [ -f "$file" ] || continue
        while IFS= read -r line || [ -n "$line" ]; do
            value="$(printf '%s' "$line" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            case "$value" in
                ""|\#*) continue ;;
                http://*|https://*)
                    printf '%s\n' "$value"
                    return 0
                    ;;
            esac

            extracted_url="$(printf '%s\n' "$value" | sed -n 's/.*\(https\{0,1\}:\/\/[^[:space:]]*\).*/\1/p')"
            case "$extracted_url" in
                http://*|https://*)
                    printf '%s\n' "$extracted_url"
                    return 0
                    ;;
            esac
        done < "$file"
    done
    return 1
}

file_size_bytes() {
    target="$1"
    [ -f "$target" ] || return 1
    wc -c < "$target" 2>/dev/null | tr -d '[:space:]'
}

remote_content_length() {
    url="$1"
    downloader="$(resolve_downloader)" || return 1
    url="$(normalize_download_url "$url")"
    debug_log "HEAD $url via $downloader"

    if debug_enabled; then
        size="$("$downloader" -fsSIL --http1.1 --retry 3 --retry-delay 1 -o /dev/null -w '%{content_length_download}' "$url")" || return 1
    else
        size="$("$downloader" -fsSIL --http1.1 --retry 3 --retry-delay 1 -o /dev/null -w '%{content_length_download}' "$url" 2>/dev/null)" || return 1
    fi
    size="$(printf '%s' "$size" | tr -d '\r' | sed 's/\..*$//')"

    case "$size" in
        ''|-1|*[!0-9]*) return 1 ;;
    esac

    printf '%s\n' "$size"
}

normalize_download_url() {
    url="$1"

    case "$url" in
        https://raw.githubusercontent.com/*/refs/heads/*)
            printf '%s\n' "$url" | sed 's#^https://raw\.githubusercontent\.com/\([^/]*\)/\([^/]*\)/refs/heads/\([^/]*\)/#https://raw.githubusercontent.com/\1/\2/\3/#'
            return 0
            ;;
        https://github.com/*/raw/refs/heads/*)
            printf '%s\n' "$url" | sed 's#^https://github\.com/\([^/]*\)/\([^/]*\)/raw/refs/heads/\([^/]*\)/#https://raw.githubusercontent.com/\1/\2/\3/#'
            return 0
            ;;
    esac

    printf '%s\n' "$url"
}

# curl_is_functional <path>
#   Returns 0 if the binary exists, is executable, and actually loads (no ABI/linker errors).
#   Sends a dummy request to an unreachable address to trigger lazy symbol binding.
curl_is_functional() {
    [ -x "$1" ] || return 1
    _cif_out="$("$1" -IsS -m 1 https://127.0.0.2 2>&1)"
    case "$_cif_out" in
        *"CANNOT LINK"*|*"cannot locate symbol"*|*"No such file"*|*"not found"*|*"is for EM_"*|*"unexpected e_machine"*) return 1 ;;
    esac
    return 0
}

# resolve_downloader
#   Finds a working curl binary.  Priority order:
#     1. $MODPATH/curl          (bundled, preferred)
#     2. $MODPATH/system/bin/curl  (alternative bundled location)
#     3. /system/bin/curl, /system/xbin/curl, /data/local/tmp/curl (common Android paths)
#     4. whatever `command -v curl` finds (system PATH)
#   Each candidate is verified with curl_is_functional so ABI mismatches are skipped.
#   Result is cached in _RESOLVED_CURL to avoid repeated probes within the same session.
_RESOLVED_CURL=""
resolve_downloader() {
    # Return cached result if already resolved
    if [ -n "$_RESOLVED_CURL" ] && curl_is_functional "$_RESOLVED_CURL"; then
        printf '%s\n' "$_RESOLVED_CURL"
        return 0
    fi

    # Candidate list — evaluated in order
    _curl_candidates="
$MODPATH/curl
$MODPATH/system/bin/curl
/system/bin/curl
/system/xbin/curl
/data/local/tmp/curl
$(command -v curl 2>/dev/null)
"
    for _cand in $_curl_candidates; do
        [ -n "$_cand" ] || continue
        if curl_is_functional "$_cand"; then
            _RESOLVED_CURL="$_cand"
            printf '%s\n' "$_cand"
            return 0
        fi
    done

    return 1
}

resolve_wget() {
    downloader="$(command -v wget 2>/dev/null)"
    [ -n "$downloader" ] || return 1
    printf '%s\n' "$downloader"
}

download_with_curl() {
    _dwc_downloader="$1"
    _dwc_url="$2"
    _dwc_output="$3"

    [ -n "$_dwc_downloader" ] || return 1
    [ -n "$_dwc_url" ] || return 1
    [ -n "$_dwc_output" ] || return 1

    debug_log "curl download: $_dwc_url -> $_dwc_output via $_dwc_downloader"
    if debug_enabled; then
        "$_dwc_downloader" -fSL -v --http1.1 --retry 3 --retry-delay 1 --connect-timeout 15 -o "$_dwc_output" "$_dwc_url"
    else
        "$_dwc_downloader" -fsSL --http1.1 --retry 3 --retry-delay 1 --connect-timeout 15 -o "$_dwc_output" "$_dwc_url" >/dev/null 2>&1
    fi
}

download_with_wget() {
    _dww_downloader="$1"
    _dww_url="$2"
    _dww_output="$3"

    [ -n "$_dww_downloader" ] || return 1
    [ -n "$_dww_url" ] || return 1
    [ -n "$_dww_output" ] || return 1

    debug_log "wget download: $_dww_url -> $_dww_output via $_dww_downloader"
    if debug_enabled; then
        "$_dww_downloader" -S -O "$_dww_output" "$_dww_url"
    else
        "$_dww_downloader" -q -O "$_dww_output" "$_dww_url" >/dev/null 2>&1
    fi
}

alternate_download_url() {
    url="$1"

    case "$url" in
        https://raw.githubusercontent.com/*)
            printf '%s\n' "$url" | sed 's#^https://raw\.githubusercontent\.com/\([^/]*\)/\([^/]*\)/\([^/]*\)/#https://github.com/\1/\2/raw/refs/heads/\3/#'
            return 0
            ;;
        https://github.com/*/raw/refs/heads/*)
            printf '%s\n' "$url" | sed 's#^https://github\.com/\([^/]*\)/\([^/]*\)/raw/refs/heads/\([^/]*\)/#https://raw.githubusercontent.com/\1/\2/\3/#'
            return 0
            ;;
    esac

    return 1
}

should_skip_download() {
    url="$1"
    target="$2"

    [ -f "$target" ] || return 1
    remote_size="$(remote_content_length "$url")" || return 1
    local_size="$(file_size_bytes "$target")" || return 1
    [ "$local_size" = "$remote_size" ]
}

download_file() {
    _df_url="$1"
    _df_output="$2"
    tmp="${_df_output}.tmp"
    alt_url=""

    [ -n "$_df_url" ] || return 1
    [ -n "$_df_output" ] || return 1
    _df_url="$(normalize_download_url "$_df_url")"
    alt_url="$(alternate_download_url "$_df_url" 2>/dev/null || true)"
    mkdir -p "$(dirname "$_df_output")" || return 1
    rm -f "$tmp"

    debug_log "download_file requested: $_df_url -> $_df_output"
    [ -n "$alt_url" ] && debug_log "alternate download URL available: $alt_url"

    downloader="$(resolve_downloader 2>/dev/null || true)"
    if [ -n "$downloader" ]; then
        if download_with_curl "$downloader" "$_df_url" "$tmp"; then
            if [ -f "$tmp" ] && mv "$tmp" "$_df_output"; then
                return 0
            fi
            rm -f "$tmp"
            debug_log "failed to move downloaded file into place: $tmp -> $_df_output"
        fi
        debug_log "curl download failed for: $_df_url"

        if [ -n "$alt_url" ] && download_with_curl "$downloader" "$alt_url" "$tmp"; then
            if [ -f "$tmp" ] && mv "$tmp" "$_df_output"; then
                return 0
            fi
            rm -f "$tmp"
            debug_log "failed to move downloaded alternate file into place: $tmp -> $_df_output"
        fi
        [ -n "$alt_url" ] && debug_log "curl alternate download failed for: $alt_url"
    fi

    downloader="$(resolve_wget 2>/dev/null || true)"
    if [ -n "$downloader" ]; then
        if download_with_wget "$downloader" "$_df_url" "$tmp"; then
            if [ -f "$tmp" ] && mv "$tmp" "$_df_output"; then
                return 0
            fi
            rm -f "$tmp"
            debug_log "failed to move downloaded file into place: $tmp -> $_df_output"
        fi
        debug_log "wget download failed for: $_df_url"

        if [ -n "$alt_url" ] && download_with_wget "$downloader" "$alt_url" "$tmp"; then
            if [ -f "$tmp" ] && mv "$tmp" "$_df_output"; then
                return 0
            fi
            rm -f "$tmp"
            debug_log "failed to move downloaded alternate file into place: $tmp -> $_df_output"
        fi
        [ -n "$alt_url" ] && debug_log "wget alternate download failed for: $alt_url"
    fi

    rm -f "$tmp"
    debug_log "all download methods failed for: $_df_url"
    return 1
}

backup_file() {
    target="$1"
    bak="${target}.bak"

    [ -f "$target" ] || return 0
    [ -f "$bak" ] && return 0
    cp -p "$target" "$bak" >/dev/null 2>&1
}

refresh_linked_file() {
    target="$1"
    shift
    bak="${target}.bak"
    url="$(read_link_file "$@")" || url=""
    case "$url" in
        http://*|https://*)
            should_skip_download "$url" "$target" && return 0
            case "$target" in
                "$LIST_DIR"/*|"$IPSET_DIR"/*)
                    rm -f "$bak"
                    ;;
                *)
                    [ -f "$bak" ] || backup_file "$target"
                    ;;
            esac
            download_file "$url" "$target" || return 1
            ;;
        *)
            rm -f "$bak"
            ;;
    esac
}

# Append one user overlay file to its refreshed dnscrypt base, idempotently. The base may
# have just been re-downloaded (refresh_linked_file) or already carry a previous overlay;
# either way we first strip everything from our marker onward, then re-append the user
# rules. The marker line is a comment ("#...") in all three formats, so dnscrypt ignores it.
append_dnscrypt_user_overlay() {
    _ov_base="$1"; _ov_user="$2"
    [ -f "$_ov_base" ] || return 0
    [ -f "$_ov_user" ] || return 0
    if grep -qF '### ZAPRET-USER-OVERLAY ###' "$_ov_base" 2>/dev/null; then
        if awk '/### ZAPRET-USER-OVERLAY ###/{exit} {print}' "$_ov_base" > "$_ov_base.ovtmp" 2>/dev/null; then
            cat "$_ov_base.ovtmp" > "$_ov_base"
        fi
        rm -f "$_ov_base.ovtmp"
    fi
    printf '\n### ZAPRET-USER-OVERLAY ###\n' >> "$_ov_base"
    cat "$_ov_user" >> "$_ov_base"
}

# After the dnscrypt base lists are refreshed, append the user's own rules so they are
# never lost when a base list is updated. Idempotent (safe to re-run). Called at the end
# of refresh_linked_lists and by the dnscrypt supervisor before dnscrypt-proxy loads them.
apply_dnscrypt_user_overlays() {
    append_dnscrypt_user_overlay "$DNSCRYPT_DIR/cloaking-rules.txt" "$DNSCRYPT_CLOAKING_USER_FILE"
    append_dnscrypt_user_overlay "$DNSCRYPT_DIR/blocked-names.txt"  "$DNSCRYPT_BLOCKED_NAMES_USER_FILE"
    append_dnscrypt_user_overlay "$DNSCRYPT_DIR/blocked-ips.txt"    "$DNSCRYPT_BLOCKED_IPS_USER_FILE"
}

refresh_linked_lists() {
    refresh_linked_file "$DNSCRYPT_DIR/cloaking-rules.txt" "$DNSCRYPT_CLOAKING_LINK" "$DNSCRYPT_CLOAKING_LINK_LEGACY" || true
    refresh_linked_file "$DNSCRYPT_DIR/blocked-names.txt" "$DNSCRYPT_BLOCKED_NAMES_LINK" "$DNSCRYPT_BLOCKED_NAMES_LINK_LEGACY" || true
    refresh_linked_file "$DNSCRYPT_DIR/blocked-ips.txt" "$DNSCRYPT_BLOCKED_IPS_LINK" || true
    refresh_linked_file "$LIST_DIR/list-general.txt" "$LIST_GENERAL_LINK" "$LIST_GENERAL_LINK_LEGACY" || true
    # User rules are appended LAST so they always win over / extend the refreshed base.
    apply_dnscrypt_user_overlays
}

ensure_telegram_bypass_defaults() {
    set_default_file "$TELEGRAM_BYPASS_FILE" "0"
    set_default_file "$TELEGRAM_BYPASS_PORT_FILE" "1443"
    if [ ! -e "$TELEGRAM_BYPASS_SECRET_FILE" ]; then
        _hex="$(cat /dev/urandom 2>/dev/null | head -c 16 | od -An -tx1 | tr -d ' \n')"
        printf '%s\n' "$_hex" > "$TELEGRAM_BYPASS_SECRET_FILE"
    fi
}

tg_ws_proxy_running() {
    [ -f "$TG_WS_PROXY_PID_FILE" ] || return 1
    _pid="$(cat "$TG_WS_PROXY_PID_FILE" 2>/dev/null)"
    [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null
}

start_tg_ws_proxy() {
    config_enabled "$TELEGRAM_BYPASS_FILE" "0" || return 0
    [ -x "$TERMUX_PYTHON" ] || return 1
    [ -f "$TG_WS_PROXY_DIR/run.py" ] || return 1
    tg_ws_proxy_running && return 0

    _port="$(cat "$TELEGRAM_BYPASS_PORT_FILE" 2>/dev/null)"
    _port="${_port:-1443}"
    _secret="$(cat "$TELEGRAM_BYPASS_SECRET_FILE" 2>/dev/null)"
    [ -n "$_secret" ] || return 1

    set -- --host 127.0.0.1 --port "$_port" --secret "$_secret"

    _pool="$(cat "$TELEGRAM_BYPASS_POOL_SIZE_FILE" 2>/dev/null)"
    [ -n "$_pool" ] && set -- "$@" --pool-size "$_pool"

    _bufkb="$(cat "$TELEGRAM_BYPASS_BUFKB_FILE" 2>/dev/null)"
    [ -n "$_bufkb" ] && set -- "$@" --buf-kb "$_bufkb"

    config_enabled "$TELEGRAM_BYPASS_VERBOSE_FILE" "0" && set -- "$@" -v

    _cfproxy="$(cat "$TELEGRAM_BYPASS_CFPROXY_FILE" 2>/dev/null)"
    [ "$_cfproxy" = "0" ] && set -- "$@" --no-cfproxy

    _cfdomain="$(cat "$TELEGRAM_BYPASS_CFPROXY_DOMAIN_FILE" 2>/dev/null)"
    [ -n "$_cfdomain" ] && set -- "$@" --cfproxy-domain "$_cfdomain"

    _cfworker="$(cat "$TELEGRAM_BYPASS_CFWORKER_DOMAIN_FILE" 2>/dev/null)"
    [ -n "$_cfworker" ] && set -- "$@" --cfproxy-worker-domain "$_cfworker"

    if [ -f "$TELEGRAM_BYPASS_DC_IP_FILE" ]; then
        while IFS= read -r _line || [ -n "$_line" ]; do
            _line="$(printf '%s' "$_line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [ -n "$_line" ] && set -- "$@" --dc-ip "$_line"
        done < "$TELEGRAM_BYPASS_DC_IP_FILE"
    fi

    export LD_LIBRARY_PATH="/data/data/com.termux/files/usr/lib:${LD_LIBRARY_PATH:-}"
    nohup "$TERMUX_PYTHON" "$TG_WS_PROXY_DIR/run.py" "$@" \
        > "$TG_WS_PROXY_LOG_FILE" 2>&1 &
    echo $! > "$TG_WS_PROXY_PID_FILE"
}

stop_tg_ws_proxy() {
    terminate_pidfile_gracefully "$TG_WS_PROXY_PID_FILE"
    pkill -TERM -f "tg-ws-proxy/run.py" >/dev/null 2>&1 || true
}

tg_proxy_deep_link() {
    _port="$(cat "$TELEGRAM_BYPASS_PORT_FILE" 2>/dev/null)"
    _port="${_port:-1443}"
    _secret="$(cat "$TELEGRAM_BYPASS_SECRET_FILE" 2>/dev/null)"
    [ -n "$_secret" ] || return 1
    printf 'tg://proxy?server=127.0.0.1&port=%s&secret=dd%s' "$_port" "$_secret"
}

stop_module_service() {
    _dnscrypt_script="$(dnscrypt_script_path)"
    terminate_pidfile_gracefully "$ZAPRET_PID_FILE"
    terminate_pidfile_gracefully "$NFQWS_PID_FILE"
    terminate_pidfile_gracefully "$DNSCRYPT_SUP_PID_FILE"
    terminate_pidfile_gracefully "$DNSCRYPT_PID_FILE"

    pkill -TERM -f "$ZAPRET_DIR/zapret.sh" >/dev/null 2>&1 || true
    pkill -TERM -f "$_dnscrypt_script" >/dev/null 2>&1 || true
    [ "$_dnscrypt_script" = "$MODPATH/dnscrypt/dnscrypt.sh" ] || pkill -TERM -f "$MODPATH/dnscrypt/dnscrypt.sh" >/dev/null 2>&1 || true
    pkill -TERM -x nfqws >/dev/null 2>&1 || true
    pkill -TERM -x nfqws2 >/dev/null 2>&1 || true
    pkill -TERM -x dnscrypt-proxy >/dev/null 2>&1 || true
    sleep 1
    pkill -KILL -f "$ZAPRET_DIR/zapret.sh" >/dev/null 2>&1 || true
    pkill -KILL -f "$_dnscrypt_script" >/dev/null 2>&1 || true
    [ "$_dnscrypt_script" = "$MODPATH/dnscrypt/dnscrypt.sh" ] || pkill -KILL -f "$MODPATH/dnscrypt/dnscrypt.sh" >/dev/null 2>&1 || true
    pkill -KILL -x nfqws >/dev/null 2>&1 || true
    pkill -KILL -x nfqws2 >/dev/null 2>&1 || true
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
