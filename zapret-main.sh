#!/system/bin/sh
MODPATH="/data/adb/modules/zapret"
UPDATEONSTART=$(cat "$MODPATH/config/update-on-start" 2>/dev/null || echo "1")
while true; do
    if ping -c 1 google.com &>/dev/null; then
        break
    else
        sleep 1
    fi
done
if [ "$UPDATEONSTART" = "1" ]; then
    . $MODPATH/update.sh > /dev/null 2>&1 &
    sleep 5
fi
if [ "$(cat "$MODPATH/config/dnscrypt-enable")" = "1" ]; then
    . $MODPATH/dnscrypt/dnscrypt.sh > /dev/null 2>&1 &
    sleep 5
fi
. $MODPATH/zapret/zapret.sh > /dev/null 2>&1 &