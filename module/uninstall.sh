#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"

stop_service() {
    for pid in $(pgrep -f "zapret.sh"); do
        kill -9 "$pid" >/dev/null 2>&1
    done
    pkill -x nfqws >/dev/null 2>&1
    pkill -x dnscrypt-proxy >/dev/null 2>&1
    pkill -f "zapret/zapret.sh" >/dev/null 2>&1
    pkill zapret >/dev/null 2>&1

    sysctl net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1
    sysctl net.ipv6.conf.default.disable_ipv6=0 >/dev/null 2>&1
    sysctl net.ipv6.conf.lo.disable_ipv6=0 >/dev/null 2>&1
    sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 >/dev/null 2>&1
    sysctl net.netfilter.nf_conntrack_checksum=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1

    iptables -t mangle -F POSTROUTING >/dev/null 2>&1
    iptables -t mangle -F PREROUTING >/dev/null 2>&1
    iptables -F OUTPUT >/dev/null 2>&1
    iptables -F FORWARD >/dev/null 2>&1
    iptables -t nat -F OUTPUT >/dev/null 2>&1
    iptables -t nat -F PREROUTING >/dev/null 2>&1
    ip6tables -t mangle -F POSTROUTING >/dev/null 2>&1
    ip6tables -t mangle -F PREROUTING >/dev/null 2>&1
    ip6tables -F OUTPUT >/dev/null 2>&1
    ip6tables -F FORWARD >/dev/null 2>&1

    echo "- Service stopped"
    return 0
}

stop_service
