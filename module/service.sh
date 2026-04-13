#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

# Wait for boot to complete before doing anything
wait_for_boot_complete

# Start services
if [ -f "$MODPATH/system/bin/zapret" ]; then
    sh "$MODPATH/system/bin/zapret" start >/dev/null 2>&1
fi
