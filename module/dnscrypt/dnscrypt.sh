MODPATH=/data/adb/modules/zapret

while true; do
    if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
        . "$MODPATH/dnscrypt/make-unkillable.sh" &
        "$MODPATH/dnscrypt/dnscrypt-proxy"
    fi
    sleep 5
done
