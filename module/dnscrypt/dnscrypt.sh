MODPATH=/data/adb/modules/zapret

while true; do
    if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
            . "$MODPATH/dnscrypt/make-unkillable-dnscrypt.sh" &
	    "$MODPATH/dnscrypt/dnscrypt-proxy" > /dev/null
    fi
    sleep 5
done
