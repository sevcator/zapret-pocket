#!/system/bin/sh
MODPATH="/data/adb/modules/zapret"
UPDATEONSTART=$(cat "$MODPATH/config/update-on-start" 2>/dev/null || echo "1")
touch "$MODPATH/dnscrypt/cloaking-rules.txt"
touch "$MODPATH/dnscrypt/custom-cloaking-rules.txt"
touch "$MODPATH/dnscrypt/blocked-names.txt"
touch "$MODPATH/dnscrypt/blocked-ips.txt"
touch "$MODPATH/ipset/custom.txt"
touch "$MODPATH/ipset/exclude.txt"
touch "$MODPATH/ipset/ipset-v4.txt"
touch "$MODPATH/ipset/ipset-v6.txt"
touch "$MODPATH/list/custom.txt"
touch "$MODPATH/list/default.txt"
touch "$MODPATH/list/exclude.txt"
touch "$MODPATH/list/providers.txt"
touch "$MODPATH/list/google.txt"
touch "$MODPATH/list/reestr.txt"
if [ "$UPDATEONSTART" = "1" ]; then
    . "$MODPATH/update.sh" > /dev/null 2>&1
    sleep 2
fi
if [ "$(cat "$MODPATH/config/dnscrypt-enable" 2>/dev/null)" = "1" ]; then
    nohup sh "$MODPATH/dnscrypt/dnscrypt.sh" > /dev/null 2>&1 &
fi
nohup sh "$MODPATH/zapret/zapret.sh" > /dev/null 2>&1 &

