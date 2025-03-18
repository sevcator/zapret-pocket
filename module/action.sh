#!/system/bin/bash
MODPATH=/data/adb/modules/zapret

echo "**********************************"
echo "*         zapret-magisk          *"
echo "**********************************"
echo ! Note: The button Action toggle zapret
echo ! To the configure, call zapret in Terminal
su -c "$MODPATH/system/bin/zapret toggle"
