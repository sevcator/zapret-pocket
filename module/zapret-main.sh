boot_wait() {
    while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done
}

boot_wait

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

mode=$(cat "$MODPATH/config/dnscrypt-cloaking-update")

if [ "$mode" = "2" ]; then
    LINK_TO_FILE=$(cat "$MODPATH/config/cloaking-rules-link")
    if [ -n "$LINK_TO_FILE" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL -o "$MODPATH/dnscrypt/cloaking-rules.txt" "$LINK_TO_FILE"
        else
            echo "curl not found, cant download file" >> "$MODPATH/warns.log"
        fi
    else
        echo "Cloaking rules link not find" >> "$MODPATH/warns.log"
    fi
fi

dnsmode=$(cat "$MODPATH/config/current-dns-mode")
if [ "$dnsmode" = "1" ]; then
    CURRENTDNS="127.0.0.2"
    nohup "$MODPATH/dnscrypt/dnscrypt.sh" > /dev/null 2>&1 &
    sleep 5
    for iface in all default lo; do
        sysctl "net.ipv6.conf.$iface.disable_ipv6=1" > /dev/null
    done
    for proto in udp tcp; do
        iptables -t nat -I OUTPUT -p "$proto" --dport 53 -j DNAT --to "$CURRENTDNS"
        iptables -t nat -I PREROUTING -p "$proto" --dport 53 -j DNAT --to "$CURRENTDNS"
    done
    for chain in OUTPUT FORWARD; do
        for proto in udp tcp; do
            ip6tables -I "$chain" -p "$proto" --dport 53 -j DROP
        done
    done
    for table in iptables ip6tables; do
        for chain in OUTPUT FORWARD; do
            for proto in udp tcp; do
                $table -I "$chain" -p "$proto" --dport 853 -j DROP
            done
        done
    done
fi

nohup "$MODPATH/zapret/zapret.sh" > /dev/null 2>&1 &
