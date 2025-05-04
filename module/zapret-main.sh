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

while true; do
    if ping -c 1 google.com &> /dev/null; then
        break
    else
        sleep 1
    fi
done

if [ "$(cat "$MODPATH/config/dnscrypt-cloaking-update")" = "1" ]; then
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

if [ "$(cat "$MODPATH/config/dnscrypt-enable")" = "1" ]; then
    nohup "$MODPATH/dnscrypt/dnscrypt.sh" > /dev/null 2>&1 &
    sleep 5
    for iface in all default lo; do
        sysctl "net.ipv6.conf.$iface.disable_ipv6=1" > /dev/null
    done
    for proto in udp tcp; do
        iptables -t nat -I OUTPUT -p "$proto" --dport 53 -j DNAT --to 127.0.0.2:53
        iptables -t nat -I PREROUTING -p "$proto" --dport 53 -j DNAT --to 127.0.0.2:53
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