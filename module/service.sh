#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

# Wait for boot to complete before doing anything
wait_for_boot_complete

# Kernel tweaks that improve DPI bypass reliability (write via /proc/sys so they
# work even where the sysctl binary is absent — e.g. toybox-only environments).
# tcp_timestamps MUST be 1: the upstream Flowseal strategies fool the DPI via the TCP
# timestamp option (--dpi-desync-fooling=ts). Windows ships timestamps ON, so Flowseal
# works on PC; Android ships them OFF. With timestamps=0 the `ts` fooling has no option
# to corrupt and silently fails (Cloudflare in particular), which is why an earlier port
# disabled them and swapped every strategy to md5sig. Keeping them ON restores parity
# with the PC and is harmless to md5sig strategies (md5sig does not depend on this knob).
write_sysctl_value net.ipv4.tcp_timestamps 1 || true
write_sysctl_value net.netfilter.nf_conntrack_tcp_be_liberal 1 || true
# (The broader network tuning — BBR, fq_codel, mtu_probing, buffers, conntrack_max —
# is applied with restore-on-stop by apply_optional_network_tweaks during start.)

# Force apps onto the module-controlled resolver: if Android Private DNS (DoT, port
# 853) is enabled, DNS goes encrypted straight to a system DoT server, bypassing our
# 53->dnscrypt redirect, so censored domains resolve uncloaked. Disable it at boot
# unless the user opted out (config/keep-private-dns = 1). (Idea from ZDT-D.)
if [ "$(cat "$MODPATH/config/keep-private-dns" 2>/dev/null || echo 0)" != "1" ]; then
    settings put global private_dns_mode off 2>/dev/null || true
fi

ensure_telegram_bypass_defaults

# Start services via CLI (handles pidfile checks, firewall setup, etc.)
if [ -f "$MODPATH/system/bin/zapret" ]; then
    nohup sh "$MODPATH/system/bin/zapret" start >/dev/null 2>&1 &
fi

# Start Telegram bypass proxy after a delay (needs network up)
(sleep 15; start_tg_ws_proxy) &
