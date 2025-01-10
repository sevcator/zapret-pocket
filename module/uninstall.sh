#!/system/bin/sh

MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret

su -c "pkill -f '/data/adb/service.d/zapret.sh'"
su -c "pkill -f '${MODDIR}/zapret.sh'"
su -c "pkill -f '${MODDIR}/service.sh'"
su -c 'pkill nfqws'
su -c 'pkill zapret'
su -c 'iptables -t mangle -F PREROUTING'
su -c 'iptables -t mangle -F POSTROUTING'
