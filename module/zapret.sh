#!/system/bin/sh

boot_wait() {
    while [ -z "$(getprop sys.boot_completed)" ]; do sleep 2; done
}

boot_wait

sysctl net.netfilter.nf_conntrack_tcp_be_liberal=1 >/dev/null 2>&1
sysctl net.netfilter.nf_conntrack_checksum=0 >/dev/null 2>&1
sysctl -w net.ipv4.tcp_timestamps=0 >/dev/null 2>&1

MODPATH=/data/adb/modules/zapret
STRATEGYDIR="$MODPATH/zapret"
CONFIG_DIR="$MODPATH/config"
CURLPATH="$MODPATH/curl"
NFQWS_BIN="$STRATEGYDIR/nfqws"
DEBUG_ENABLE=$(cat "$CONFIG_DIR/debug" 2>/dev/null || echo "0")
CURRENTSTRATEGY=$(cat "$CONFIG_DIR/current-strategy" 2>/dev/null || echo "")
HAS_IP6TABLES=0
DEBUG_LOG="$CONFIG_DIR/debug.log"

[ -x "$NFQWS_BIN" ] || NFQWS_BIN="$MODPATH/nfqws"

if [ "$DEBUG_ENABLE" = "1" ]; then
    mkdir -p "$CONFIG_DIR"
    touch "$DEBUG_LOG"
    exec >>"$DEBUG_LOG" 2>&1
    set -x
fi

if command -v ip6tables >/dev/null 2>&1 && [ -r /proc/net/ip6_tables_targets ]; then
    HAS_IP6TABLES=1
fi

read_link_file() {
    for file in "$@"; do
        [ -f "$file" ] || continue
        if grep -q '[^[:space:]]' "$file" 2>/dev/null; then
            cat "$file"
            return 0
        fi
    done
    return 1
}

download_file() {
    url="$1"
    output="$2"
    tmp="${output}.tmp"
    downloader=""

    [ -n "$url" ] || return 1
    [ -n "$output" ] || return 1

    if [ -x "$CURLPATH" ]; then
        downloader="$CURLPATH"
    elif command -v curl >/dev/null 2>&1; then
        downloader="$(command -v curl)"
    else
        return 1
    fi

    if "$downloader" -fsSL --retry 3 --retry-delay 1 -o "$tmp" "$url" >/dev/null 2>&1; then
        mv "$tmp" "$output"
        return 0
    fi

    rm -f "$tmp"
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
            [ -f "$bak" ] && return 0
            backup_file "$target"
            download_file "$url" "$target"
            ;;
        *)
            rm -f "$bak"
            return 0
            ;;
    esac
}

refresh_linked_lists() {
    refresh_linked_file "$MODPATH/dnscrypt/cloaking-rules.txt" \
        "$CONFIG_DIR/dnscrypt-cloaking-rules-link" \
        "$CONFIG_DIR/custom-cloaking-rules-url"
    refresh_linked_file "$MODPATH/dnscrypt/blocked-names.txt" \
        "$CONFIG_DIR/dnscrypt-blocked-names-link" \
        "$CONFIG_DIR/custom-blocked-names-url"
    refresh_linked_file "$MODPATH/list/list-general.txt" \
        "$CONFIG_DIR/list-general-link" \
        "$CONFIG_DIR/custom-list-general-url"
}

run_strategy() {
    [ -n "$CURRENTSTRATEGY" ] || return 1
    [ -f "$STRATEGYDIR/$CURRENTSTRATEGY.sh" ] || return 1
    . "$STRATEGYDIR/$CURRENTSTRATEGY.sh"
}

apply_ipv6_tweaks() {
    sysctl net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
    sysctl net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
    sysctl net.ipv6.conf.lo.disable_ipv6=1 >/dev/null 2>&1
    [ "$HAS_IP6TABLES" = 1 ] || return 0
    for file in /proc/sys/net/ipv6/conf/*/accept_ra; do
        [ -w "$file" ] && echo 0 > "$file"
    done
    for file in /proc/sys/net/ipv6/conf/*/disable_ipv6; do
        [ -w "$file" ] && echo 1 > "$file"
    done
}

apply_dnscrypt_firewall() {
    iptables -I OUTPUT -p udp --dport 853 -j DROP
    iptables -I OUTPUT -p tcp --dport 853 -j DROP
    iptables -I FORWARD -p udp --dport 853 -j DROP
    iptables -I FORWARD -p tcp --dport 853 -j DROP
    [ "$HAS_IP6TABLES" = 1 ] || return 0
    ip6tables -I OUTPUT -p udp --dport 853 -j DROP
    ip6tables -I OUTPUT -p tcp --dport 853 -j DROP
    ip6tables -I FORWARD -p udp --dport 853 -j DROP
    ip6tables -I FORWARD -p tcp --dport 853 -j DROP
}

tcp_ports="$(printf '%s\n' "$config" | grep -oE 'filter-tcp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' -e 's/ /,/g' | sort -un)";
udp_ports="$(printf '%s\n' "$config" | grep -oE 'filter-udp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' -e 's/ /,/g' | sort -un)";

iptAdd() {
    iptDPort="$iMportD $2"; iptSPort="$iMportS $2";
    iptables -t mangle -I POSTROUTING -p $1 $iptDPort $iCBo $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
    iptables -t mangle -I PREROUTING -p $1 $iptSPort $iCBr $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
}

ip6tAdd() {
    [ "$HAS_IP6TABLES" = 1 ] || return 0
    ip6tDPort="$i6MportD $2"; ip6tSPort="$i6MportS $2";
    ip6tables -t mangle -I POSTROUTING -p $1 $ip6tDPort $i6CBo $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass;
    ip6tables -t mangle -I PREROUTING -p $1 $ip6tSPort $i6CBr $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass;
}

addMultiPort() {
    for current_port in $2; do
        case "$current_port" in
            *-*)
            start_port=${current_port%-*}
            end_port=${current_port#*-}
            current_i=$start_port
            while [ "$current_i" -le "$end_port" ]; do
                iptAdd "$1" "$current_i"
                ip6tAdd "$1" "$current_i"
                current_i=$((current_i + 1))
            done
            ;;
            *)
            iptAdd "$1" "$current_port"
            ip6tAdd "$1" "$current_port"
            ;;
        esac
    done
}

if [ "$(cat /proc/net/ip_tables_targets | grep -c 'NFQUEUE')" = "0" ]; then
    exit
fi
if [ "$HAS_IP6TABLES" = 1 ] && [ "$(cat /proc/net/ip6_tables_targets | grep -c 'NFQUEUE')" = "0" ]; then
    HAS_IP6TABLES=0
fi

if [ "$(cat /proc/net/ip_tables_matches | grep -c 'multiport')" != "0" ]; then
    iMportS="-m multiport --sports"
    iMportD="-m multiport --dports"
else
    iMportS="--sport"
    iMportD="--dport"
fi
if [ "$HAS_IP6TABLES" = 1 ] && [ "$(cat /proc/net/ip6_tables_matches | grep -c 'multiport')" != "0" ]; then
    i6MportS="-m multiport --sports"
    i6MportD="-m multiport --dports"
else
    i6MportS="--sport"
    i6MportD="--dport"
fi

if [ "$(cat /proc/net/ip_tables_matches | grep -c 'connbytes')" != "0" ]; then
    iCBo="-m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:12"
    iCBr="-m connbytes --connbytes-dir=reply --connbytes-mode=packets --connbytes 1:3"
else
    iCBo=""
    iCBr=""
fi
if [ "$HAS_IP6TABLES" = 1 ] && [ "$(cat /proc/net/ip6_tables_matches | grep -c 'connbytes')" != "0" ]; then
    i6CBo="-m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:12"
    i6CBr="-m connbytes --connbytes-dir=reply --connbytes-mode=packets --connbytes 1:3"
else
    i6CBo=""
    i6CBr=""
fi

if [ "$(cat /proc/net/ip_tables_matches | grep -c 'mark')" != "0" ]; then
    iMark="-m mark ! --mark 0x40000000/0x40000000"
else
    iMark=""
fi
if [ "$HAS_IP6TABLES" = 1 ] && [ "$(cat /proc/net/ip6_tables_matches | grep -c 'mark')" != "0" ]; then
    i6Mark="-m mark ! --mark 0x40000000/0x40000000"
else
    i6Mark=""
fi

refresh_linked_lists
run_strategy || exit 0
[ "$DEBUG_ENABLE" = "1" ] && config="$config --debug=1"
apply_ipv6_tweaks
apply_dnscrypt_firewall

addMultiPort "tcp" "$tcp_ports"
addMultiPort "udp" "$udp_ports"

while true; do
    if ! pgrep -x "nfqws" > /dev/null; then
            . "$MODPATH/make-unkillable.sh" &
            if [ "$DEBUG_ENABLE" = "1" ]; then
	            "$NFQWS_BIN" --uid=0:0 --bind-fix4 --bind-fix6 --qnum=200 $config
            else
	            "$NFQWS_BIN" --uid=0:0 --bind-fix4 --bind-fix6 --qnum=200 $config > /dev/null
            fi
    fi
    sleep 5
done
