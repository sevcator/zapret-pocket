MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret

ui_print "- Mounting /data"
mount -o remount,rw /data || abort "! Failed to remount /data"

check_requirements() {
  if command -v iptables >/dev/null 2>&1; then
    ui_print "- iptables: Found"
  else
    abort "! iptables: Not found"
  fi

  if command -v ip6tables >/dev/null 2>&1; then
    ui_print "- ip6tables: Found"
  else
    abort "! ip6tables: Not found"
  fi

  if [ "$(cat /proc/net/ip_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    ui_print "! Bad iptables"
    abort
  fi

  if [ "$(cat /proc/net/ip6_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    abort "! Bad ip6tables"
  fi

  API=$(grep_get_prop ro.build.version.sdk)
  if [ -n "$API" ]; then
    ui_print "- Device Android API: $API"
    if [ "$API" -lt 28 ]; then
      abort "! Minimum required API 28 (Android 9)"
    fi
  else
    abort "! Failed to detect Android API"
  fi
}

binary_by_architecture() {
    ABI=$(grep_get_prop ro.product.cpu.abi)
    case "$ABI" in
        arm64-v8a)
            BINARY="nfqws-aarch64"
            BINARY2="dnscrypt-proxy-arm64"
            ;;
        x86_64)
            BINARY="nfqws-x86_x64"
            BINARY2="dnscrypt-proxy-x86_64"
            ;;
        armeabi-v7a)
            BINARY="nfqws-arm"
            BINARY2="dnscrypt-proxy-arm"
            ;;
        x86)
            BINARY="nfqws-x86"
            BINARY2="dnscrypt-proxy-i386"
            ;;
        *)
            abort "! Unsupported Architecture: $ABI"
            ;;
    esac
    ui_print "- Device architecture: $ABI"
    ui_print "- zapret binary: $BINARY"
    ui_print "- dnscrypt-proxy binary: $BINARY2"
}

check_requirements
binary_by_architecture

for pid in $(pgrep -f zapret.sh); do
    kill -9 "$pid"
done
for pid in $(pgrep -f dnscrypt.sh); do
    kill -9 "$pid"
done
pkill nfqws
pkill zapret
pkill dnscrypt-proxy

ui_print "- Cleaning iptables rules"
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

for FILE in "$MODPATH"/*.sh "$MODPATH/strategies/"*.sh "$MODUPDATEPATH"/*.sh "$MODUPDATEPATH/strategies/"*.sh; do
    [ -f "$FILE" ] && sed -i 's/\r$//' "$FILE"
done

mv "$MODPATH/$BINARY" "$MODPATH/nfqws"
mv "$MODPATH/dnscrypt/$BINARY2" "$MODPATH/dnscrypt/dnscrypt-proxy"
mv "$MODUPDATEPATH/$BINARY" "$MODUPDATEPATH/nfqws"
mv "$MODUPDATEPATH/dnscrypt/$BINARY2" "$MODUPDATEPATH/dnscrypt/dnscrypt-proxy"
rm -f "$MODPATH/nfqws-"*
rm -f "$MODPATH/dnscrypt/dnscrypt-proxy-"*
rm -f "$MODUPDATEPATH/nfqws-"*
rm -f "$MODUPDATEPATH/dnscrypt/dnscrypt-proxy-"*

set_perm_recursive "$MODPATH" 0 2000 0755 0755
set_perm_recursive "$MODUPDATEPATH" 0 2000 0755 0755

ui_print "- Disabling Private DNS"
settings put global private_dns_mode off

ui_print "- Disabling Tethering Hardware Acceleration"
settings put global tether_offload_disabled 1

ui_print "* sevcator.t.me / sevcator.github.io *"

ui_print "! Clear DNS Cache and disable Private DNS Server on your browser!"

ui_print "- Reboot to take changes"
