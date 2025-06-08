MODPATH="/data/adb/modules/zapret"
while true; do
    if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
        . "$MODPATH/dnscrypt/make-unkillable.sh" &
        for proto in udp tcp; do
            iptables -t nat -I OUTPUT -p "$proto" --dport 53 -j DNAT --to 127.0.0.1:5253
            iptables -t nat -I PREROUTING -p "$proto" --dport 53 -j DNAT --to 127.0.0.1:5253
        done
        for iface in all default lo; do
            sysctl net.ipv6.conf.$iface.disable_ipv6=1
        done
        "$MODPATH/dnscrypt/dnscrypt-proxy"
    fi
    sleep 5
done
