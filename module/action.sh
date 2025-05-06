#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"

echo "! Zapret Module for Magisk; @sevcator/zapret-magisk"
echo ""
echo "! This operation may take some time"
echo "" 
if pgrep -f "nfqws" >/dev/null 2>&1; then
    if su -c "$MODPATH/uninstall.sh" &>/dev/null 2>&1; then
        echo "- Service stopped"
    else
        echo "- Failed to stop service"
    fi
else
    if su -c "$MODPATH/service.sh" &>/dev/null 2>&1; then
        echo "- Service started"
    else
        echo "- Failed to start service"
    fi
fi