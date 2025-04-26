#!/system/bin/sh

MODPATH=/data/adb/modules/zapret
su -c "$MODPATH/uninstall.sh"
sleep 2
$MODPATH/main.sh &
