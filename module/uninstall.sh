#!/system/bin/sh
for iface in all default lo; do
    sysctl "net.ipv6.conf.$iface.disable_ipv6=0" > /dev/null 2>&1 &
done
sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 > /dev/null 2>&1
sysctl net.netfilter.nf_conntrack_checksum=1 > /dev/null > /dev/null 2>&1
PROCS=("zapret.sh" "zapret-main.sh" "dnscrypt.sh" "nfqws" "dnscrypt-proxy")
for proc in "${PROCS[@]}"; do
    pkill -9 -f "$proc" 2>/dev/null
    while pgrep -f "$proc" > /dev/null; do
        sleep 0.2
    done
done
iptables -t mangle -F POSTROUTING
iptables -t mangle -F PREROUTING
iptables -t nat -F OUTPUT
iptables -t nat -F PREROUTING
iptables -F OUTPUT
iptables -F FORWARD
ip6tables -F OUTPUT
ip6tables -F FORWARD