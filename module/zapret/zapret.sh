MODPATH=/data/adb/modules/zapret

boot_wait() {
    while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done
}

boot_wait

call_error() {
    echo "[$DATE] $1" >> "$MODPATH/error.log"
}

for FILE in "$MODPATH"/*.sh "$MODPATH/strategy/"*.sh "$MODPATH/dnscrypt/"*.sh; do
    [ -f "$FILE" ] && sed -i 's/\r$//' "$FILE"
done

if [ ! -f "$MODPATH/config/current-strategy" ]; then
    call_error "$MODPATH/config/current-strategy not found!"
    exit
fi

if [ ! -f "$MODPATH/config/current-plain-dns" ]; then
    call_error "$MODPATH/config/current-plain-dns not found!"
    exit
fi

if [ ! -f "$MODPATH/config/current-dns-mode" ]; then
    call_error "$MODPATH/config/current-dns-mode not found!"
    exit
fi

CURRENTSTRATEGY=$(cat $MODPATH/config/current-strategy)
CURRENTDNS=$(cat $MODPATH/config/current-plain-dns)
. "$MODPATH/strategy/$CURRENTSTRATEGY.sh"

iptables -t mangle -F POSTROUTING
iptables -t mangle -F PREROUTING
iptables -F OUTPUT
iptables -F FORWARD
iptables -t nat -F OUTPUT
iptables -t nat -F PREROUTING
ip6tables -t mangle -F POSTROUTING
ip6tables -t mangle -F PREROUTING
ip6tables -F OUTPUT
ip6tables -F FORWARD

while true; do
    if ping -c 1 google.com &> /dev/null; then
        break
    else
        sleep 1
    fi
done

if [ -f "$MODPATH/config/current-dns-mode" ] && [ "$(cat "$MODPATH/config/current-dns-mode")" = "2" ]; then
    . "$MODPATH/dnscrypt/dnscrypt.sh" &
    CURRENTDNS=127.0.0.2
else
    for pid in $(pgrep -f dnscrypt.sh); do
        kill -9 "$pid"
    done
    pkill dnscrypt-proxy
fi

if [ "$(cat $MODPATH/config/current-dns-mode)" != "0" ]; then
    sysctl net.ipv6.conf.all.disable_ipv6=1 > /dev/null;
    sysctl net.ipv6.conf.default.disable_ipv6=1 > /dev/null;
    sysctl net.ipv6.conf.lo.disable_ipv6=1 > /dev/null;
    iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to $CURRENTDNS:53
    iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to $CURRENTDNS:53
    iptables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to $CURRENTDNS:53
    iptables -t nat -I PREROUTING -p tcp --dport 53 -j DNAT --to $CURRENTDNS:53
    echo -n 1 >/proc/sys/net/ipv4/conf/all/route_localnet
fi

if [ "$(cat $MODPATH/current-advanced-rules)" = "1" ]; then
    iptables -I OUTPUT -p udp --dport 853 -j DROP
    iptables -I OUTPUT -p tcp --dport 853 -j DROP
    iptables -I FORWARD -p udp --dport 853 -j DROP
    iptables -I FORWARD -p tcp --dport 853 -j DROP
    ip6tables -I OUTPUT -p udp --dport 53 -j DROP
    ip6tables -I OUTPUT -p tcp --dport 53 -j DROP
    ip6tables -I FORWARD -p udp --dport 53 -j DROP
    ip6tables -I FORWARD -p tcp --dport 53 -j DROP
    ip6tables -I OUTPUT -p udp --dport 853 -j DROP
    ip6tables -I OUTPUT -p tcp --dport 853 -j DROP
    ip6tables -I FORWARD -p udp --dport 853 -j DROP
    ip6tables -I FORWARD -p tcp --dport 853 -j DROP
    pm set-user-restriction --user 0 no_config_vpn 1
    pm set-user-restriction --user 0 no_config_tethering 1
fi

tcp_ports="$(echo $config | grep -oE 'filter-tcp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' -e 's/ /,/g' | sort -un)";
udp_ports="$(echo $config | grep -oE 'filter-udp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' -e 's/ /,/g' | sort -un)";

iptAdd() {
    iptDPort="$iMportD $2"; iptSPort="$iMportS $2";
    iptables -t mangle -I POSTROUTING -p $1 $iptDPort $iCBo $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
    iptables -t mangle -I PREROUTING -p $1 $iptSPort $iCBr $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
}

ip6tAdd() {
    ip6tDPort="$i6MportD $2"; ip6tSPort="$i6MportS $2";
    ip6tables -t mangle -I POSTROUTING -p $1 $ip6tDPort $i6CBo $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass;
    ip6tables -t mangle -I PREROUTING -p $1 $ip6tSPort $i6CBr $i6Mark -j NFQUEUE --queue-num 200 --queue-bypass;
}

addMultiPort() {
    for current_port in $2; do
        if [[ $current_port == *-* ]]; then
            for i in $(seq ${current_port%-*} ${current_port#*-}); do
                iptAdd "$1" "$i";
		ip6tAdd "$1" "$i";
            done
        else
            iptAdd "$1" "$current_port";
	    ip6tAdd "$1" "$current_port";
        fi
    done
}

if [ "$(cat /proc/net/ip_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    call_error "iptables is bad!"
    exit
fi
if [ "$(cat /proc/net/ip6_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    call_error "ip6tables is bad!"
    exit
fi

if [ "$(cat /proc/net/ip_tables_matches | grep -c 'multiport')" != "0" ]; then
    iMportS="-m multiport --sports"
    iMportD="-m multiport --dports"
else
    iMportS="--sport"
    iMportD="--dport"
fi
if [ "$(cat /proc/net/ip6_tables_matches | grep -c 'multiport')" != "0" ]; then
    i6MportS="-m multiport --sports"
    i6MportD="-m multiport --dports"
else
    i6MportS="--sport"
    i6MportD="--dport"
fi

if iptables -t mangle -A POSTROUTING -p tcp -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:12 -j ACCEPT 2>/dev/null; then
    iptables -t mangle -D POSTROUTING -p tcp -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:12 -j ACCEPT 2>/dev/null
    cbOrig="-m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:12"
    cbReply="-m connbytes --connbytes-dir=reply --connbytes-mode=packets --connbytes 1:6"
else
    cbOrig=""
    cbReply=""
fi

if [ "$(cat /proc/net/ip_tables_matches | grep -c 'connbytes')" != "0" ]; then
    iCBo="$cbOrig"
    iCBr="$cbReply"
else
    iCBo=""
    iCBr=""
fi

if [ "$(cat /proc/net/ip_tables_matches | grep -c 'mark')" != "0" ]; then
    iMark="-m mark ! --mark 0x40000000/0x40000000"
else
    iMark=""
fi
if [ "$(cat /proc/net/ip6_tables_matches | grep -c 'mark')" != "0" ]; then
    i6Mark="-m mark ! --mark 0x40000000/0x40000000"
else
    i6Mark=""
fi

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

addMultiPort "tcp" "$tcp_ports";
addMultiPort "udp" "$udp_ports";

while true; do
    if ! pgrep -x "nfqws" > /dev/null; then
            . "$MODPATH/zapret/make-unkillable.sh" &
	    "$MODPATH/zapret/nfqws" --uid=0:0 --bind-fix4 --bind-fix6 --qnum=200 $config > /dev/null
    fi
    sleep 5
done
