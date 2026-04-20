#!/system/bin/sh

MODPATH="${MODPATH:-/data/adb/modules/zapret}"
CONFIG_DIR="${CONFIG_DIR:-$MODPATH/config}"
LIST_DIR="${LIST_DIR:-$MODPATH/list}"
LEGACY_LIST_DIR="${LEGACY_LIST_DIR:-$MODPATH/lists}"
IPSET_DIR="${IPSET_DIR:-$MODPATH/list}"
ZAPRET_DIR="${ZAPRET_DIR:-$MODPATH/zapret}"
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
DNSCRYPT_CLOAKING_LINK="$CONFIG_DIR/dnscrypt-cloaking-rules-link"
DNSCRYPT_CLOAKING_LINK_LEGACY="$CONFIG_DIR/custom-cloaking-rules-url"
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
        case "$(basename "$file")" in
            zapret.sh|make-unkillable.sh) continue ;;
        esac
        cp -af "$file" "$STRATEGY_DIR/" 2>/dev/null || true
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
    mkdir -p "$CONFIG_DIR" "$LIST_DIR" "$IPSET_DIR" "$ZAPRET_DIR" "$STRATEGY_DIR" "$DNSCRYPT_DIR" "$SERVICE_DIR" "$STATE_DIR"

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
                "$DNSCRYPT_DIR/blocked-ips.txt"; do
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

dnscrypt_supervisor_is_running() {
    pidfile_is_running "$DNSCRYPT_SUP_PID_FILE" && return 0
    pgrep -f "$MODPATH/dnscrypt/dnscrypt.sh" >/dev/null 2>&1
}

dnscrypt_is_running() {
    pidfile_is_running "$DNSCRYPT_PID_FILE" && return 0
    pgrep -x dnscrypt-proxy >/dev/null 2>&1
}

nfqws_is_running() {
    pidfile_is_running "$NFQWS_PID_FILE" && return 0
    pgrep -x nfqws >/dev/null 2>&1
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
        *"CANNOT LINK"*|*"cannot locate symbol"*|*"No such file"*|*"not found"*) return 1 ;;
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
    downloader="$1"
    url="$2"
    output="$3"

    [ -n "$downloader" ] || return 1
    [ -n "$url" ] || return 1
    [ -n "$output" ] || return 1

    debug_log "curl download: $url -> $output via $downloader"
    if debug_enabled; then
        "$downloader" -fSL -v --http1.1 --retry 3 --retry-delay 1 --connect-timeout 15 -o "$output" "$url"
    else
        "$downloader" -fsSL --http1.1 --retry 3 --retry-delay 1 --connect-timeout 15 -o "$output" "$url" >/dev/null 2>&1
    fi
}

download_with_wget() {
    downloader="$1"
    url="$2"
    output="$3"

    [ -n "$downloader" ] || return 1
    [ -n "$url" ] || return 1
    [ -n "$output" ] || return 1

    debug_log "wget download: $url -> $output via $downloader"
    if debug_enabled; then
        "$downloader" -S -O "$output" "$url"
    else
        "$downloader" -q -O "$output" "$url" >/dev/null 2>&1
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
    url="$1"
    output="$2"
    tmp="${output}.tmp"
    alt_url=""

    [ -n "$url" ] || return 1
    [ -n "$output" ] || return 1
    url="$(normalize_download_url "$url")"
    alt_url="$(alternate_download_url "$url" 2>/dev/null || true)"

    debug_log "download_file requested: $url -> $output"
    [ -n "$alt_url" ] && debug_log "alternate download URL available: $alt_url"

    downloader="$(resolve_downloader 2>/dev/null || true)"
    if [ -n "$downloader" ]; then
        if download_with_curl "$downloader" "$url" "$tmp"; then
            mv "$tmp" "$output"
            return 0
        fi
        debug_log "curl download failed for: $url"

        if [ -n "$alt_url" ] && download_with_curl "$downloader" "$alt_url" "$tmp"; then
            mv "$tmp" "$output"
            return 0
        fi
        [ -n "$alt_url" ] && debug_log "curl alternate download failed for: $alt_url"
    fi

    downloader="$(resolve_wget 2>/dev/null || true)"
    if [ -n "$downloader" ]; then
        if download_with_wget "$downloader" "$url" "$tmp"; then
            mv "$tmp" "$output"
            return 0
        fi
        debug_log "wget download failed for: $url"

        if [ -n "$alt_url" ] && download_with_wget "$downloader" "$alt_url" "$tmp"; then
            mv "$tmp" "$output"
            return 0
        fi
        [ -n "$alt_url" ] && debug_log "wget alternate download failed for: $alt_url"
    fi

    rm -f "$tmp"
    debug_log "all download methods failed for: $url"
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

refresh_linked_lists() {
    refresh_linked_file "$DNSCRYPT_DIR/cloaking-rules.txt" "$DNSCRYPT_CLOAKING_LINK" "$DNSCRYPT_CLOAKING_LINK_LEGACY" || true
    refresh_linked_file "$DNSCRYPT_DIR/blocked-names.txt" "$DNSCRYPT_BLOCKED_NAMES_LINK" "$DNSCRYPT_BLOCKED_NAMES_LINK_LEGACY" || true
    refresh_linked_file "$LIST_DIR/list-general.txt" "$LIST_GENERAL_LINK" "$LIST_GENERAL_LINK_LEGACY" || true
}

stop_module_service() {
    terminate_pidfile_gracefully "$ZAPRET_PID_FILE"
    terminate_pidfile_gracefully "$NFQWS_PID_FILE"
    terminate_pidfile_gracefully "$DNSCRYPT_SUP_PID_FILE"
    terminate_pidfile_gracefully "$DNSCRYPT_PID_FILE"

    pkill -TERM -f "$ZAPRET_DIR/zapret.sh" >/dev/null 2>&1 || true
    pkill -TERM -f "$MODPATH/dnscrypt/dnscrypt.sh" >/dev/null 2>&1 || true
    pkill -TERM -x nfqws >/dev/null 2>&1 || true
    pkill -TERM -x dnscrypt-proxy >/dev/null 2>&1 || true
    sleep 1
    pkill -KILL -f "$ZAPRET_DIR/zapret.sh" >/dev/null 2>&1 || true
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
