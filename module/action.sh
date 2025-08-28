MODPATH="/data/adb/modules/zapret"
echo "! Please wait, this action takes some time"
if pgrep -f "nfqws" >/dev/null 2>&1; then
    sh "$MODPATH/uninstall.sh" > /dev/null 2>&1
    echo "- Service stopped"
else
    sh "$MODPATH/service.sh" > /dev/null 2>&1
    echo "- Service started"
fi
