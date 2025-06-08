MODPATH="/data/adb/modules/zapret"
while true; do
    if ping -c 1 google.com &> /dev/null; then
        break
    else
        sleep 1
    fi
done
if [ "$(cat "$MODPATH/config/dnscrypt-enable")" = "1" ]; then
    . "$MODPATH/dnscrypt/update-files.sh"
    sleep 3
    nohup "$MODPATH/dnscrypt/dnscrypt.sh" > /dev/null 2>&1 &
    sleep 5
fi
nohup "$MODPATH/zapret/zapret.sh" > /dev/null 2>&1 &
