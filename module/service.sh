#!/system/bin/sh

MODPATH=/data/adb/modules/zapret
su -c "$MODPATH/uninstall.sh"
sleep 2
su -c "$MODPATH/zapret-main.sh"
