MODPATH="/data/adb/modules/zapret"
IPV6ENABLE=$(cat "$MODPATH/config/ipv6-enable" 2>/dev/null || echo "0")
NETWORKTWEAKS=$(cat "$MODPATH/config/network-tweaks" 2>/dev/null || echo "0")
# Disable TCP timestamps (ntc.party)
sysctl -w net.ipv4.tcp_timestamps=0 > /dev/null 2>&1 &
if [ "$IPV6ENABLE" != "1" ]; then
    resetprop net.ipv6.conf.default.accept_redirects 0 > /dev/null 2>&1 &
    resetprop net.ipv6.conf.all.accept_redirects 0 > /dev/null 2>&1 &
    resetprop net.ipv6.conf.default.disable_ipv6 1 > /dev/null 2>&1 &
    resetprop net.ipv6.conf.all.disable_ipv6 1 > /dev/null 2>&1 &
fi
if [ "$NETWORKTWEAKS" = "1" ]; then
    # BPF JIT
    sysctl -w net.core.bpf_jit_enable=1 > /dev/null 2>&1 &
    sysctl -w net.core.bpf_harden=0 > /dev/null 2>&1 &
    sysctl -w net.core.bpf_kallsyms=1 > /dev/null 2>&1 &
    sysctl -w net.core.bpf_limit=33554432 > /dev/null 2>&1 &
    # Busy polling
    sysctl -w net.core.busy_poll=0 > /dev/null 2>&1 &
    sysctl -w net.core.busy_read=0 > /dev/null 2>&1 &
    # Default queue discipline
    sysctl -w net.core.default_qdisc=pfifo_fast > /dev/null 2>&1 &
    # Network packet processing weight
    sysctl -w net.core.dev_weight=64 > /dev/null 2>&1 &
    sysctl -w net.core.dev_weight_rx_bias=1 > /dev/null 2>&1 &
    sysctl -w net.core.dev_weight_tx_bias=1 > /dev/null 2>&1 &
    # Flow control limits
    sysctl -w net.core.flow_limit_cpu_bitmap=00 > /dev/null 2>&1 &
    sysctl -w net.core.flow_limit_table_len=4096 > /dev/null 2>&1 &
    # Packet fragments
    sysctl -w net.core.max_skb_frags=17 > /dev/null 2>&1 &
    # Messaging
    sysctl -w net.core.message_burst=10 > /dev/null 2>&1 &
    sysctl -w net.core.message_cost=5 > /dev/null 2>&1 &
    # Netdev backlog
    sysctl -w net.core.netdev_max_backlog=28000000 > /dev/null 2>&1 &
    sysctl -w net.core.netdev_budget=1000 > /dev/null 2>&1 &
    sysctl -w net.core.netdev_budget_usecs=16000 > /dev/null 2>&1 &
    # Socket memory
    sysctl -w net.core.optmem_max=65536 > /dev/null 2>&1 &
    # Read/write buffers
    sysctl -w net.core.rmem_default=229376 > /dev/null 2>&1 &
    sysctl -w net.core.rmem_max=67108864 > /dev/null 2>&1 &
    sysctl -w net.core.wmem_default=229376 > /dev/null 2>&1 &
    sysctl -w net.core.wmem_max=67108864 > /dev/null 2>&1 &
    # Connection queue
    sysctl -w net.core.somaxconn=1024 > /dev/null 2>&1 &
    # Timestamps and XFRM
    sysctl -w net.core.tstamp_allow_data=1 > /dev/null 2>&1 &
    sysctl -w net.core.xfrm_acq_expires=3600 > /dev/null 2>&1 &
    sysctl -w net.core.xfrm_aevent_etime=10 > /dev/null 2>&1 &
    sysctl -w net.core.xfrm_aevent_rseqth=2 > /dev/null 2>&1 &
    sysctl -w net.core.xfrm_larval_drop=1 > /dev/null 2>&1 &
fi
boot_wait() {
    while [ -z "$(getprop sys.boot_completed)" ]; do sleep 2; done
}
boot_wait
sleep 2
. "$MODPATH/zapret-main.sh"
