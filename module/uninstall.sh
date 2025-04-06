#!/system/bin/sh

# Enable IPv6
sysctl net.ipv6.conf.all.disable_ipv6=0 > /dev/null;
sysctl net.ipv6.conf.default.disable_ipv6=0 > /dev/null;
sysctl net.ipv6.conf.lo.disable_ipv6=0 > /dev/null;

sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 > /dev/null;

for pid in $(pgrep -f zapret.sh); do
    kill -9 "$pid"
done
for pid in $(pgrep -f dnscrypt.sh); do
    kill -9 "$pid"
done
pkill nfqws
pkill zapret
pkill dnscrypt-proxy

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
