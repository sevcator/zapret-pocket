for iface in all default lo; do
    sysctl "net.ipv6.conf.$iface.disable_ipv6=0" > /dev/null
done
sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 > /dev/null;
for proto in udp tcp; do
    iptables -t nat -S | grep -- "-p $proto -m $proto --dport 53 -j DNAT" | while read -r rule; do
        iptables -t nat -D ${rule#-A }
    done
done
PROCS=("zapret.sh" "zapret-main.sh" "dnscrypt.sh" "nfqws")
for proc in "${PROCS[@]}"; do
    pkill -9 -f "$proc" 2>/dev/null
done
iptables -t mangle -F POSTROUTING
iptables -t mangle -F PREROUTING
