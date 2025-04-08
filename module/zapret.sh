MODPATH=/data/adb/modules/zapret

boot_wait() {
    while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done
}

boot_wait

call_error() {
    "$MODPATH/log-error.sh" "Curl/wget not found on system"
}

for FILE in "$MODPATH"/*.sh "$MODPATH/strategies/"*.sh; do
    [ -f "$FILE" ] && sed -i 's/\r$//' "$FILE"
done

if [ ! -f "$MODPATH/current-strategy" ]; then
    "$MODPATH/log-error.sh" "$MODPATH/current-strategy not found!"
    exit
fi

if [ ! -f "$MODPATH/current-dns" ]; then
    "$MODPATH/log-error.sh" "$MODPATH/current-dns not found!"
    exit
fi

if [ ! -f "$MODPATH/current-dns-selection" ]; then
    "$MODPATH/log-error.sh" "$MODPATH/current-dns-selection not found!"
    exit
fi

CURRENTSTRATEGY=$(cat $MODPATH/current-strategy)
CURRENTDNS=$(cat $MODPATH/current-dns)
. "$MODPATH/strategies/$CURRENTSTRATEGY.sh"

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

if [ -f "$MODPATH/current-dns-selection" ] && [ "$(cat "$MODPATH/current-dns-selection")" = "2" ]; then
    . "$MODPATH/dnscrypt/dnscrypt.sh" &
    CURRENTDNS=127.0.0.2
else
    for pid in $(pgrep -f dnscrypt.sh); do
        kill -9 "$pid"
    done
    pkill dnscrypt-proxy
fi

if [ "$(cat $MODPATH/current-dns-selection)" != "0" ]; then
    sysctl net.ipv6.conf.all.disable_ipv6=1 > /dev/null;
    sysctl net.ipv6.conf.default.disable_ipv6=1 > /dev/null;
    sysctl net.ipv6.conf.lo.disable_ipv6=1 > /dev/null;
    iptables -I OUTPUT -p udp --dport 853 -j DROP
    iptables -I OUTPUT -p tcp --dport 853 -j DROP
    iptables -I FORWARD -p udp --dport 853 -j DROP
    iptables -I FORWARD -p tcp --dport 853 -j DROP
    ip6tables -I OUTPUT -p udp --dport 53 -j DROP
    ip6tables -I OUTPUT -p tcp --dport 53 -j DROP
    ip6tables -I FORWARD -p udp --dport 53 -j DROP
    ip6tables -I FORWARD -p tcp --dport 53 -j DROP
    iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to $CURRENTDNS:53
    iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to $CURRENTDNS:53
    iptables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to $CURRENTDNS:53
    iptables -t nat -I PREROUTING -p tcp --dport 53 -j DNAT --to $CURRENTDNS:53
    ip6tables -I OUTPUT -p udp --dport 853 -j DROP
    ip6tables -I OUTPUT -p tcp --dport 853 -j DROP
    ip6tables -I FORWARD -p udp --dport 853 -j DROP
    ip6tables -I FORWARD -p tcp --dport 853 -j DROP
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
    "$MODPATH/log-error.sh" "iptables is bad!"
    exit
fi
if [ "$(cat /proc/net/ip6_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    "$MODPATH/log-error.sh" "ip6tables is bad!"
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

addMultiPort "tcp" "$tcp_ports";
addMultiPort "udp" "$udp_ports";

while true; do
    if ! pgrep -x "nfqws" > /dev/null; then
            . "$MODPATH/make-unkillable.sh" &
	    "$MODPATH/nfqws" --uid=0:0 --bind-fix4 --bind-fix6 --qnum=200 $config > /dev/null
    fi
    sleep 5
done
