MODPATH="/data/adb/modules/zapret"
echo "! This operation may take some time, please wait"
if pgrep -f "nfqws" >/dev/null 2>&1; then
    su -c "$MODPATH/uninstall.sh"
    echo "- Service stopped"
else
    su -c "$MODPATH/service.sh"
    echo "- Service started"
fi
