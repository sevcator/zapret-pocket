#!/system/bin/sh

MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret

sysctl net.netfilter.nf_conntrack_tcp_be_liberal=1 > /dev/null;
sysctl net.ipv6.conf.all.disable_ipv6=1 > /dev/null;
sysctl net.ipv6.conf.default.disable_ipv6=1 > /dev/null;
sysctl net.ipv6.conf.lo.disable_ipv6=1 > /dev/null;
for pid in $(grep -l "zapret.sh" /proc/*/cmdline | awk -F'/' '{print $3}'); do
    su -c "pkill -9 $pid"
done
su -c "pkill -f '${MODDIR}/zapret.sh'"
su -c "pkill -f '${MODDIR}/service.sh'"
su -c 'pkill nfqws'
su -c 'pkill zapret'
su -c 'iptables -t mangle -F PREROUTING'
su -c 'iptables -t mangle -F POSTROUTING'
