#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
echo "! Please wait, this action takes some time"

if sh "$MODPATH/system/bin/zapret" running >/dev/null 2>&1; then
    sh "$MODPATH/system/bin/zapret" stop
else
    sh "$MODPATH/system/bin/zapret" start
fi
