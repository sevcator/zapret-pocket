#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"

if [ -f "$MODPATH/system/bin/zapret" ]; then
    sh "$MODPATH/system/bin/zapret" start >/dev/null 2>&1
elif [ -f "$MODPATH/zapret.sh" ]; then
    nohup sh "$MODPATH/zapret.sh" >/dev/null 2>&1 &
fi
