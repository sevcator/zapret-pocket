#!/system/bin/sh

sysctl net.ipv6.conf.all.disable_ipv6=0 > /dev/null;
sysctl net.ipv6.conf.default.disable_ipv6=0 > /dev/null;
sysctl net.ipv6.conf.lo.disable_ipv6=0 > /dev/null;

sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 > /dev/null;

PROCS=("zapret.sh" "zapret-main.sh" "dnscrypt.sh" "nfqws")
for proc in "${PROCS[@]}"; do
    pkill -9 -f "$proc" 2>/dev/null
done

iptables -t mangle -F POSTROUTING
iptables -t mangle -F PREROUTING
iptables -t nat -S | grep -- '-p udp -m udp --dport 53 -j DNAT' | while read -r rule; do
    iptables -t nat -D ${rule#-A }
done
iptables -t nat -S | grep -- '-p tcp -m tcp --dport 53 -j DNAT' | while read -r rule; do
    iptables -t nat -D ${rule#-A }
done