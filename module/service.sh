#!/system/bin/sh

MODPATH=/data/adb/modules/zapret
$MODPATH/uninstall.sh
sleep 2
$MODPATH/zapret/zapret.sh &
