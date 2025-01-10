# If you don't know what you're doing, don't touch anything

boot_wait() {
    while [[ -z $(getprop sys.boot_completed) ]]; do sleep 5; done
}

boot_wait

MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret

. $MODPATH/load-config.sh

tcp_ports="$(echo $config | grep -oE 'filter-tcp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' -e 's/ /,/g' | sort -un)";
udp_ports="$(echo $config | grep -oE 'filter-udp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' -e 's/ /,/g' | sort -un)";
sysctl net.netfilter.nf_conntrack_tcp_be_liberal=1 > /dev/null;

iptAdd() {
    iptDPort="$iMportD $2"; iptSPort="$iMportS $2";
    iptables -t mangle -I POSTROUTING -p $1 $iptDPort $iCBo $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
    iptables -t mangle -I PREROUTING -p $1 $iptSPort $iCBr $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
}

iptMultiPort() {
    for current_port in $2; do
        if [[ $current_port == *-* ]]; then
            for i in $(seq ${current_port%-*} ${current_port#*-}); do
                iptAdd "$1" "$i";
            done
        else
            iptAdd "$1" "$current_port";
        fi
    done
}

if [ "$(cat /proc/net/ip_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    exit
else
    if [ "$(cat /proc/net/ip_tables_matches | grep -c 'multiport')" != "0" ]; then
        iMportS="-m multiport --sports"
        iMportD="-m multiport --dports"
    else
        iMportS="--sport"
        iMportD="--dport"
    fi

    if [ "$(cat /proc/net/ip_tables_matches | grep -c 'connbytes')" != "0" ]; then
        iCBo="-m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:12"
        iCBr="-m connbytes --connbytes-dir=reply --connbytes-mode=packets --connbytes 1:3"
    else
        iCBo=""
        iCBr=""
    fi

    if [ "$(cat /proc/net/ip_tables_matches | grep -c 'mark')" != "0" ]; then
        iMark="-m mark ! --mark 0x40000000/0x40000000"
    else
        iMark=""
    fi

    iptMultiPort "tcp" "$tcp_ports";
    iptMultiPort "udp" "$udp_ports";
fi

while true; do
    if ! pgrep -x "nfqws" > /dev/null; then
	   "$MODPATH/nfqws" --uid=0:0 --bind-fix4 --bind-fix6 --qnum=200 $config
    fi
    if ! iptables -t mangle -L POSTROUTING | grep -q "NFQUEUE"; then
        iptMultiPort "tcp" "$tcp_ports";
        iptMultiPort "udp" "$udp_ports";
    fi
    sleep 5
done
