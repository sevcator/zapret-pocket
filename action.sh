MODPATH="/data/adb/modules/zapret"
if pgrep -f "nfqws" >/dev/null 2>&1; then
    su -c "$MODPATH/uninstall.sh" > /dev/null 2>&1
    echo "- Service stopped"
else
    su -c "$MODPATH/service.sh" > /dev/null 2>&1
    echo "- Service started"
fi
