#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
echo "! Please wait, this action takes some time"

status="$(sh "$MODPATH/system/bin/zapret" status 2>/dev/null)"

case "$status" in
    running)
        sh "$MODPATH/system/bin/zapret" stop
        ;;
    degraded)
        echo "! Detected degraded state, restarting service"
        sh "$MODPATH/system/bin/zapret" restart
        ;;
    *)
        sh "$MODPATH/system/bin/zapret" start
        ;;
esac
