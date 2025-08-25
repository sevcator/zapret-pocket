#!/system/bin/sh
MODPATH="/data/adb/modules/zapret"
SELF="$$"
PARENT="$PPID"
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")"
PIDS_FROM_DIR="$(pgrep -f "$MODPATH" 2>/dev/null || true)"
for pid in $PIDS_FROM_DIR; do
    [ "$pid" = "$SELF" ] && continue
    [ "$pid" = "$PARENT" ] && continue
    if [ -r "/proc/$pid/cmdline" ] && \
       tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
        continue
    fi
    if [ -d "/proc/$pid" ]; then
        renice -n 0 -p "$pid" 2>/dev/null
        if [ -w "/proc/$pid/oom_score_adj" ]; then
            echo 0 > "/proc/$pid/oom_score_adj"
        elif [ -w "/proc/$pid/oom_adj" ]; then
            echo 0 > "/proc/$pid/oom_adj"
        fi
        kill -9 "$pid" 2>/dev/null
        while [ -d "/proc/$pid" ]; do
            sleep 0.2
        done
        echo "- Killed process, ID: $pid"
    fi
done
for iface in all default lo; do
    resetprop net.ipv6.conf.all.disable_ipv6 0
    resetprop net.ipv6.conf.default.disable_ipv6 0
    resetprop net.ipv6.conf.all.accept_redirects 1
    resetprop net.ipv6.conf.default.accept_redirects 1
done
sysctl net.netfilter.nf_conntrack_tcp_be_liberal=0 > /dev/null 2>&1
sysctl net.netfilter.nf_conntrack_checksum=1 > /dev/null 2>&1
echo 0 > /proc/sys/net/ipv4/conf/all/route_localnet
for chain in PREROUTING OUTPUT FORWARD; do
  for proto in udp tcp; do
    if iptables -t nat -C $chain -p $proto --dport 53 -j DNAT --to-destination 127.0.0.1:5253 2>/dev/null; then
      iptables -t nat -D $chain -p $proto --dport 53 -j DNAT --to-destination 127.0.0.1:5253
    fi
    if ip6tables -t nat -C $chain -p $proto --dport 53 -j REDIRECT --to-ports 5253 2>/dev/null; then
      ip6tables -t nat -D $chain -p $proto --dport 53 -j REDIRECT --to-ports 5253
    fi
  done
done
for chain in OUTPUT FORWARD; do
  for proto in udp tcp; do
    if iptables -t filter -C $chain -p $proto --dport 853 -j DROP 2>/dev/null; then
      iptables -t filter -D $chain -p $proto --dport 853 -j DROP
    fi
    if ip6tables -t filter -C $chain -p $proto --dport 853 -j DROP 2>/dev/null; then
      ip6tables -t filter -D $chain -p $proto --dport 853 -j DROP
    fi
  done
done
for ipt in iptables ip6tables; do
  for chain in PREROUTING POSTROUTING; do
    if $ipt -t mangle -C $chain -j NFQUEUE --queue-num 200 --queue-bypass 2>/dev/null; then
      $ipt -t mangle -D $chain -j NFQUEUE --queue-num 200 --queue-bypass
    fi
  done
done
. "$MODPATH/dnscrypt/custom-cloaking-rules.sh" disappend > /dev/null 2>&1