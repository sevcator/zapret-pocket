MODPATH=/data/adb/modules/zapret

boot_wait() {
    while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done
}

boot_wait

for FILE in "$MODPATH"/*.sh "$MODPATH/strategy/"*.sh "$MODPATH/zapret/"*.sh "$MODPATH/dnscrypt/"*.sh; do
    [ -f "$FILE" ] && sed -i 's/\r$//' "$FILE"
done
set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  local CON=$5
  [ -z $CON ] && CON=u:object_r:system_file:s0
  chcon $CON $1 || return 1
}
set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}
set_perm_recursive "$MODPATH" 0 2000 0755 0755

for config_file in current-strategy current-plain-dns current-dns-mode current-advanced-rules; do
    if [ ! -f "$MODPATH/config/$config_file" ]; then
        echo "$MODPATH/$config_file not found!" >> "$MODPATH/error.log"
        exit
    fi
done

if [ "$(cat "$MODPATH/config/current-dns-mode")" = "2" ]; then
    . "$MODPATH/dnscrypt/dnscrypt.sh" &
else
    for pid in $(pgrep -f dnscrypt.sh); do
        kill -9 "$pid"
    done
    pkill dnscrypt-proxy
fi

if [ "$(cat $MODPATH/config/current-dns-mode)" = "1" ]; then
    sysctl net.ipv6.conf.all.disable_ipv6=1 > /dev/null
    sysctl net.ipv6.conf.default.disable_ipv6=1 > /dev/null
    sysctl net.ipv6.conf.lo.disable_ipv6=1 > /dev/null
    iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to $CURRENTDNS
    iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to $CURRENTDNS
    iptables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to $CURRENTDNS
    iptables -t nat -I PREROUTING -p tcp --dport 53 -j DNAT --to $CURRENTDNS
fi

if [ "$(cat $MODPATH/config/current-advanced-rules)" = "1" ]; then
    ip6tables -I OUTPUT -p udp --dport 53 -j DROP
    ip6tables -I OUTPUT -p tcp --dport 53 -j DROP
    ip6tables -I FORWARD -p udp --dport 53 -j DROP
    ip6tables -I FORWARD -p tcp --dport 53 -j DROP
    iptables -I OUTPUT -p udp --dport 853 -j DROP
    iptables -I OUTPUT -p tcp --dport 853 -j DROP
    iptables -I FORWARD -p udp --dport 853 -j DROP
    iptables -I FORWARD -p tcp --dport 853 -j DROP
    ip6tables -I OUTPUT -p udp --dport 853 -j DROP
    ip6tables -I OUTPUT -p tcp --dport 853 -j DROP
    ip6tables -I FORWARD -p udp --dport 853 -j DROP
    ip6tables -I FORWARD -p tcp --dport 853 -j DROP
fi
