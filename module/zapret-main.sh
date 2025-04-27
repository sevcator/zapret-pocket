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

mode=$(cat "$MODPATH/config/dnscrypt-files-mode")
if [ "$mode" = "1" ] || [ "$mode" = "2" ]; then
    CLOAKING_RULES_LINK=$(cat "$MODPATH/config/cloaking-rules-link")
    
    if [ -n "$CLOAKING_RULES_LINK" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL -o "$MODPATH/dnscrypt/cloaking-rules.txt" "$CLOAKING_RULES_LINK"
        else
            echo "- curl not found, cannot download cloaking rules" >> "$MODPATH/warns.log"
        fi
    else
        echo "- Cloaking rules link is empty" >> "$MODPATH/warns.log"
    fi
fi
if [ "$mode" = "2" ]; then
    BLOCKED_NAMES_LINK=$(cat "$MODPATH/config/blocked-names-link")

    if [ -n "$BLOCKED_NAMES_LINK" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL -o "$MODPATH/dnscrypt/blocked-names.txt" "$BLOCKED_NAMES_LINK"
        else
            echo "- curl not found, cannot download blocked names" >> "$MODPATH/warns.log"
        fi
    else
        echo "- Blocked names link is empty" >> "$MODPATH/warns.log"
    fi
fi

dnsmode=$(cat "$MODPATH/config/current-dns-mode")
if [ "$dnsmode" = "1" ]; then
    CURRENTDNS=$(cat "$MODPATH/config/current-plain-dns")
fi
if [ "$dnsmode" = "2" ]; then
    CURRENTDNS="127.0.0.2"
    nohup "$MODPATH/dnscrypt/dnscrypt.sh" > /dev/null 2>&1 &
fi
if [ "$dnsmode" = "1" ] || [ "$dnsmode" = "2" ]; then
    sysctl net.ipv6.conf.all.disable_ipv6=1 > /dev/null
    sysctl net.ipv6.conf.default.disable_ipv6=1 > /dev/null
    sysctl net.ipv6.conf.lo.disable_ipv6=1 > /dev/null
    iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to $CURRENTDNS:53
    iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to $CURRENTDNS:53
    iptables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to $CURRENTDNS:53
    iptables -t nat -I PREROUTING -p tcp --dport 53 -j DNAT --to $CURRENTDNS:53
fi

nohup "$MODPATH/zapret/zapret.sh" > /dev/null 2>&1 &
