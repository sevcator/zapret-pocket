#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
REFRESH=$(cat "$MODPATH/config/dnscrypt-rules-fix" 2>/dev/null || echo "0")

setup() {
  echo 1 >/proc/sys/net/ipv4/conf/all/route_localnet
  for chain in PREROUTING OUTPUT FORWARD; do
    for proto in udp tcp; do
      iptables -t nat -C "$chain" -p $proto --dport 53 -j DNAT --to-destination 127.0.0.1:5253 2>/dev/null || iptables -t nat -A "$chain" -p $proto --dport 53 -j DNAT --to-destination 127.0.0.1:5253
      ip6tables -t nat -C "$chain" -p $proto --dport 53 -j REDIRECT --to-ports 5253 2>/dev/null || ip6tables -t nat -A "$chain" -p $proto --dport 53 -j REDIRECT --to-ports 5253
    done
  done
  for chain in OUTPUT FORWARD; do
    for proto in udp tcp; do
      iptables -t filter -C $chain -p $proto --dport 853 -j DROP 2>/dev/null || iptables -t filter -A $chain -p $proto --dport 853 -j DROP
      ip6tables -t filter -C $chain -p $proto --dport 853 -j DROP 2>/dev/null || ip6tables -t filter -A $chain -p $proto --dport 853 -j DROP
    done
  done
}

start_bg(){
  [ -x "$MODPATH/dnscrypt/make-unkillable.sh" ] && nohup sh "$MODPATH/dnscrypt/make-unkillable.sh" >/dev/null 2>&1 &
  [ -x "$MODPATH/dnscrypt/dnscrypt-proxy" ] || { echo "dnscrypt-proxy not found" >&2; exit 1; }
  pgrep -x dnscrypt-proxy >/dev/null || "$MODPATH/dnscrypt/dnscrypt-proxy" >/dev/null 2>&1 &
}

start_fg(){
  [ -x "$MODPATH/dnscrypt/make-unkillable.sh" ] && nohup sh "$MODPATH/dnscrypt/make-unkillable.sh" >/dev/null 2>&1 &
  [ -x "$MODPATH/dnscrypt/dnscrypt-proxy" ] || { echo "dnscrypt-proxy not found" >&2; exit 1; }
  "$MODPATH/dnscrypt/dnscrypt-proxy" >/dev/null 2>&1
}

if [ "$REFRESH" = "1" ]; then
  while true; do
    setup
    start_bg
    sleep 5
  done
else
  while true; do
    setup
    start_fg
    sleep 5
  done
fi
