#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
echo "! Please wait, this action takes some time"

if pgrep -f "zapret.sh" >/dev/null 2>&1 || pgrep -f "nfqws" >/dev/null 2>&1; then
    if sh "$MODPATH/system/bin/zapret" stop >/dev/null 2>&1; then
        echo "- Service stopped"
    else
        echo "! Failed to stop service"
    fi
else
    if sh "$MODPATH/system/bin/zapret" start >/dev/null 2>&1; then
        echo "- Service started"
    else
        echo "! Failed to start service"
    fi
fi
