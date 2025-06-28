#!/system/bin/sh
MODPATH="/data/adb/modules/zapret"
rules() {
  for proto in udp tcp; do
    if ! iptables -t nat -C OUTPUT -p $proto --dport 53 -j REDIRECT --to-ports 5253 2>/dev/null; then
      iptables -t nat -A OUTPUT -p $proto --dport 53 -j REDIRECT --to-ports 5253
    fi
    if ! iptables -t nat -C PREROUTING -p $proto --dport 53 -j DNAT --to-destination 127.0.0.1:5253 2>/dev/null; then
      iptables -t nat -A PREROUTING -p $proto --dport 53 -j DNAT --to-destination 127.0.0.1:5253
    fi
  done
  for table in iptables ip6tables; do
      for chain in OUTPUT FORWARD; do
          for proto in udp tcp; do
              $table -I "$chain" -p "$proto" --dport 853 -j DROP
          done
      done
  done
  for iface in all default lo; do
    sysctl "net.ipv6.conf.$iface.disable_ipv6=1" > /dev/null 2>&1
  done
}
main() {
  "$MODPATH/dnscrypt/dnscrypt-proxy" > /dev/null 2>&1
}
while true; do
  if ! pgrep -x dnscrypt-proxy > /dev/null; then
    rules
    main
  fi
  sleep 5
done