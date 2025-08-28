MODPATH="/data/adb/modules/zapret"
IPV6ENABLE=$(cat "$MODPATH/config/ipv6-enable" 2>/dev/null || echo "0")
NETWORKTWEAKS=$(cat "$MODPATH/config/network-tweaks" 2>/dev/null || echo "0")
# Disable TCP timestamps (ntc.party)
sysctl -w net.ipv4.tcp_timestamps=0
if [ "$IPV6ENABLE" != "1" ]; then
    resetprop net.ipv6.conf.default.accept_redirects 0
    resetprop net.ipv6.conf.all.accept_redirects 0
    resetprop net.ipv6.conf.default.disable_ipv6 1
    resetprop net.ipv6.conf.all.disable_ipv6 1
fi
if [ "$NETWORKTWEAKS" = "1" ]; then
    # BPF JIT
    sysctl -w net.core.bpf_jit_enable=1
    sysctl -w net.core.bpf_harden=0
    sysctl -w net.core.bpf_kallsyms=1
    sysctl -w net.core.bpf_limit=33554432
    # Busy polling
    sysctl -w net.core.busy_poll=0
    sysctl -w net.core.busy_read=0
    # Default queue discipline
    sysctl -w net.core.default_qdisc=pfifo_fast
    # Network packet processing weight
    sysctl -w net.core.dev_weight=64
    sysctl -w net.core.dev_weight_rx_bias=1
    sysctl -w net.core.dev_weight_tx_bias=1
    # Flow control limits
    sysctl -w net.core.flow_limit_cpu_bitmap=00
    sysctl -w net.core.flow_limit_table_len=4096
    # Packet fragments
    sysctl -w net.core.max_skb_frags=17
    # Messaging
    sysctl -w net.core.message_burst=10
    sysctl -w net.core.message_cost=5
    # Netdev backlog
    sysctl -w net.core.netdev_max_backlog=28000000
    sysctl -w net.core.netdev_budget=1000
    sysctl -w net.core.netdev_budget_usecs=16000
    # Socket memory
    sysctl -w net.core.optmem_max=65536
    # Read/write buffers
    sysctl -w net.core.rmem_default=229376
    sysctl -w net.core.rmem_max=67108864
    sysctl -w net.core.wmem_default=229376
    sysctl -w net.core.wmem_max=67108864
    # Connection queue
    sysctl -w net.core.somaxconn=1024
    # Timestamps and XFRM
    sysctl -w net.core.tstamp_allow_data=1
    sysctl -w net.core.xfrm_acq_expires=3600
    sysctl -w net.core.xfrm_aevent_etime=10
    sysctl -w net.core.xfrm_aevent_rseqth=2
    sysctl -w net.core.xfrm_larval_drop=1
fi
boot_wait() {
    while [ -z "$(getprop sys.boot_completed)" ]; do sleep 2; done
}
boot_wait
sleep 2
. "$MODPATH/zapret-main.sh"
