#!/system/bin/sh

# Enable IPv6, if zapret still not works, try this.
# sysctl net.ipv6.conf.all.disable_ipv6=0 > /dev/null;
# sysctl net.ipv6.conf.default.disable_ipv6=0 > /dev/null;
# sysctl net.ipv6.conf.lo.disable_ipv6=0 > /dev/null;
sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 > /dev/null;
for pid in $(pgrep -f zapret.sh); do
    kill -9 $pid
done
su -c 'pkill nfqws'
su -c 'pkill zapret'
su -c 'iptables -t mangle -F PREROUTING'
su -c 'iptables -t mangle -F POSTROUTING'
