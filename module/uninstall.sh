for i in all default lo; do
    sysctl "net.ipv6.conf.$i.disable_ipv6=0" >/dev/null
done
sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 >/dev/null
iptables -t mangle -F
iptables -t mangle -X
ip6tables -t mangle -F
ip6tables -t mangle -X
iptables -t nat -F
iptables -t nat -X
PROCS=("zapret.sh" "zapret-main.sh" "dnscrypt.sh" "nfqws")
for p in "${PROCS[@]}"; do
    pids=$(pgrep -f "$p")
    for pid in $pids; do
        echo 0 > "/proc/$pid/oom_score_adj" 2>/dev/null
        sleep 1
        kill "$pid" 2>/dev/null
        sleep 1
        kill -9 "$pid" 2>/dev/null
    done
done
