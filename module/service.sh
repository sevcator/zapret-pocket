#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

# Wait for boot to complete before doing anything
wait_for_boot_complete

# Kernel tweaks that improve DPI bypass reliability
sysctl -w net.ipv4.tcp_timestamps=0 >/dev/null 2>&1 || true
sysctl -w net.netfilter.nf_conntrack_tcp_be_liberal=1 >/dev/null 2>&1 || true

# Start services via CLI (handles pidfile checks, firewall setup, etc.)
if [ -f "$MODPATH/system/bin/zapret" ]; then
    nohup sh "$MODPATH/system/bin/zapret" start >/dev/null 2>&1 &
fi
