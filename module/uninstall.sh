#!/system/bin/sh
for iface in all default lo; do
    sysctl "net.ipv6.conf.$iface.disable_ipv6=0" > /dev/null 2>&1
done
echo 1 > /proc/sys/net/ipv6/conf/wlan0/accept_ra
echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 > /dev/null 2>&1
sysctl net.netfilter.nf_conntrack_checksum=1 > /dev/null 2>&1
SCRIPT_PIDS=$(pgrep -f "dnscrypt.sh")
DNSCRYPT_PIDS=$(pgrep dnscrypt-proxy)
SCRIPT2_PIDS=$(pgrep -f "zapret.sh")
NFQWS_PIDS=$(pgrep nfqws)
SCRIPT3_PIDS=$(pgrep -f "zapret-main.sh")
ALL_PIDS="$SCRIPT_PIDS $DNSCRYPT_PIDS $SCRIPT2_PIDS $NFQWS_PIDS $SCRIPT3_PIDS"
for pid in $ALL_PIDS; do
    if [ -d "/proc/$pid" ]; then
        renice -n 0 -p "$pid" 2>/dev/null
        if [ -w "/proc/$pid/oom_score_adj" ]; then
            echo 0 > "/proc/$pid/oom_score_adj"
        elif [ -w "/proc/$pid/oom_adj" ]; then
            echo 0 > "/proc/$pid/oom_adj"
        fi
        kill -9 "$pid" 2>/dev/null
        while [ -d "/proc/$pid" ]; do
            sleep 0.2
        done
        echo "- Killed process, ID: $pid"
    fi
done
iptables -t mangle -F POSTROUTING
iptables -t mangle -F PREROUTING
iptables -t nat -F OUTPUT
iptables -t nat -F PREROUTING
iptables -F OUTPUT
iptables -F FORWARD
ip6tables -F OUTPUT
ip6tables -F FORWARD