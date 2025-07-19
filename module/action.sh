MODPATH="/data/adb/modules/zapret"
if pgrep -f "nfqws" >/dev/null 2>&1; then
    . "$MODPATH/uninstall.sh" > /dev/null 2>&1
    echo "- Service stopped"
else
    . "$MODPATH/service.sh" > /dev/null 2>&1
    echo "- Service started"
fi
