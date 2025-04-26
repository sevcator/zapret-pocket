MODPATH=/data/adb/modules/zapret

while true; do
    sysctl net.ipv6.conf.all.disable_ipv6=1 > /dev/null
    sysctl net.ipv6.conf.default.disable_ipv6=1 > /dev/null
    sysctl net.ipv6.conf.lo.disable_ipv6=1 > /dev/null
    iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to 127.0.0.2:53
    iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to 127.0.0.2:53
    iptables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to 127.0.0.2:53
    iptables -t nat -I PREROUTING -p tcp --dport 53 -j DNAT --to 127.0.0.2:53

    if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
        . "$MODPATH/dnscrypt/make-unkillable.sh" &
        "$MODPATH/dnscrypt/dnscrypt-proxy" > /dev/null
    fi

    sleep 5
done
