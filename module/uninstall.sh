#!/system/bin/sh

sysctl net.ipv6.conf.all.disable_ipv6=0 > /dev/null;
sysctl net.ipv6.conf.default.disable_ipv6=0 > /dev/null;
sysctl net.ipv6.conf.lo.disable_ipv6=0 > /dev/null;

sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 > /dev/null;

PROCS=("zapret.sh" "dnscrypt.sh" "nfqws" "zapret" "dnscrypt-proxy")
for proc in "${PROCS[@]}"; do
    pkill -9 -f "$proc" 2>/dev/null
done

iptables -t mangle -F POSTROUTING
iptables -t mangle -F PREROUTING
iptables -F OUTPUT
iptables -F FORWARD
iptables -t nat -F OUTPUT
iptables -t nat -F PREROUTING
ip6tables -t mangle -F POSTROUTING
ip6tables -t mangle -F PREROUTING
ip6tables -F OUTPUT
ip6tables -F FORWARD
