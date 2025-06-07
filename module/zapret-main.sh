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
    for iface in all default lo; do
        sysctl "net.ipv6.conf.$iface.disable_ipv6=1" > /dev/null
    done
    for proto in udp tcp; do
        iptables -t nat -I OUTPUT -p "$proto" --dport 53 -j DNAT --to 127.0.0.1:5253
        iptables -t nat -I PREROUTING -p "$proto" --dport 53 -j DNAT --to 127.0.0.1:5253
    done
fi
nohup "$MODPATH/zapret/zapret.sh" > /dev/null 2>&1 &
