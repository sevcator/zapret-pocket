#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

# Wait for boot to complete before doing anything
while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 2
done

# Start services
if [ -f "$MODPATH/system/bin/zapret" ]; then
    sh "$MODPATH/system/bin/zapret" start >/dev/null 2>&1
fi
