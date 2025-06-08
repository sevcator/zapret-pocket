MODPATH="/data/adb/modules/zapret"
while true; do
    if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
        . "$MODPATH/dnscrypt/make-unkillable.sh" &
        "$MODPATH/dnscrypt/dnscrypt-proxy"
    fi
    for proto in udp tcp; do
        iptables -t nat -I OUTPUT -p "$proto" --dport 53 -j DNAT --to 127.0.0.1:5253
        iptables -t nat -I PREROUTING -p "$proto" --dport 53 -j DNAT --to 127.0.0.1:5253
    done
    sleep 5
done
