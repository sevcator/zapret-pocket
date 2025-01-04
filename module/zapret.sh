boot_wait() {
    while [[ -z $(getprop sys.boot_completed) ]]; do sleep 10; done
}

boot_wait

MODDIR=/data/adb/modules/zapret
hostlist="--hostlist-exclude=$MODDIR/exclude.txt --hostlist-auto=$MODDIR/autohostlist.txt"
config="--filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODDIR/tls.bin $hostist --new"
config="$config --filter-tcp=443 --hostlist=$MODDIR/google.txt --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODDIR/tls.bin --new"
config="$config --filter-tcp=80 --hostlist=$MODDIR/google.txt --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODDIR/tls.bin --new"
config="$config --filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig --dpi-desync-fake-tls=$MODDIR/tls.bin $hostlist --new"
config="$config --filter-udp=443 --hostlist=$MODDIR/google.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODDIR/quic.bin --new"
config="$config --filter-udp=80 --hostlist=$MODDIR/google.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODDIR/quic.bin --new"
config="$config --filter-udp=80 --dpi-desync=fake --dpi-desync-repeats=11 $hostlist --new"
config="$config --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 $hostlist --new"
config="$config --filter-udp=50000-50099 --ipset=$MODDIR/ipset-discord.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n4"

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
    echo "Error - very bad iptables, script will not work"
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

check_nfqws_running() {
    if pgrep -x "nfqws" > /dev/null; then
        return 0
    else
        return 1
    fi
}

get_current_interface() {
    ip link | grep -E '^[0-9]+:' | awk '{print $2, $9}' | grep 'UP'
}
previous_interface=""

if check_nfqws_running; then
    exit 0
fi

while true; do
    if ! pgrep -x "nfqws" > /dev/null; then
	   # echo "[$(date)] nfqws not started, restarting..." >> "$MODDIR/logs.txt"
	   "$MODDIR/nfqws" --uid=0:0 --bind-fix4 --qnum=200 $config > /dev/null &
	   # echo "[$(date)] nfqws - PID $NFQWS_PID" >> "$MODDIR/logs_watchdog.txt"
    fi
    if ! iptables -t mangle -L POSTROUTING | grep -q "NFQUEUE"; then
        # echo "[$(date)] iptables rules missing, re-adding..." >> "$MODDIR/logs.txt"
        iptMultiPort "tcp" "$tcp_ports";
        iptMultiPort "udp" "$udp_ports";
    fi
    current_interfaces=$(get_current_interfaces)
    if [ "$current_interfaces" != "$previous_interfaces" ]; then
        pkill nfqws
        # echo "[$(date)] Network interfaces status changed. nfqws process restarted." >> "$MODDIR/logs_watchdog.txt"
        sleep 3
        iptMultiPort "tcp" "$tcp_ports";
        iptMultiPort "udp" "$udp_ports";
        "$MODDIR/nfqws" --uid=0:0 --qnum=200 $config > /dev/null &
    fi
    previous_interfaces=$current_interfaces
    sleep 15
done
