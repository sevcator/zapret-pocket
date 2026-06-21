#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

# Wait for boot to complete before doing anything
wait_for_boot_complete

# Kernel tweaks that improve DPI bypass reliability (write via /proc/sys so they
# work even where the sysctl binary is absent — e.g. toybox-only environments)
write_sysctl_value net.ipv4.tcp_timestamps 0 || true
write_sysctl_value net.netfilter.nf_conntrack_tcp_be_liberal 1 || true

# Start services via CLI (handles pidfile checks, firewall setup, etc.)
if [ -f "$MODPATH/system/bin/zapret" ]; then
    nohup sh "$MODPATH/system/bin/zapret" start >/dev/null 2>&1 &
fi
