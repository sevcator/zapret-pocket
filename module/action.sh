#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"

echo "! Zapret Module for Magisk; @sevcator/zapret-magisk"
echo ""
echo "! This operation may take some time, please wait"
echo "" 
if pgrep -f "nfqws" >/dev/null 2>&1; then
    if su -c "$MODPATH/uninstall.sh" &>/dev/null 2>&1; then
        sleep 5
        echo "- Service stopped"
    fi
else
    if su -c "$MODPATH/service.sh" &>/dev/null 2>&1; then
        sleep 5
        echo "- Service started"
    fi
fi
