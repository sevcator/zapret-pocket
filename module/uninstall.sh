#!/system/bin/sh

MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret

sysctl -w net.netfilter.nf_conntrack_tcp_be_liberal=1 > /dev/null;
sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null;
sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null;
sysctl -w net.ipv6.conf.lo.disable_ipv6=1 > /dev/null;
for pid in $(pgrep -f zapret.sh); do
    kill -9 $pid
done
su -c 'pkill nfqws'
su -c 'pkill zapret'
su -c 'iptables -t mangle -F PREROUTING'
su -c 'iptables -t mangle -F POSTROUTING'
