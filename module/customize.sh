MODPATH="/data/adb/modules/zapret"
MODUPDATEPATH="/data/adb/modules_update/zapret"
ui_print "- Mounting /data"
mount -o remount,rw /data
check_requirements() {
  command -v iptables >/dev/null 2>&1 || abort "! iptables: Not found"
  ui_print "- iptables: Found"
  command -v ip6tables >/dev/null 2>&1 || abort "! ip6tables: Not found"
  ui_print "- ip6tables: Found"
  grep -q 'NFQUEUE' /proc/net/ip_tables_targets || abort "! iptables - NFQUEUE: Not found"
  ui_print "- iptables - NFQUEUE: Found"
  grep -q 'NFQUEUE' /proc/net/ip6_tables_targets || abort "! ip6tables - NFQUEUE: Not found"
  ui_print "- ip6tables - NFQUEUE: Found"
  grep -q 'DNAT' /proc/net/ip_tables_targets || abort "! iptables - DNAT: Found"
  ui_print "- iptables - DNAT: Found"
  grep -q 'DNAT' /proc/net/ip6_tables_targets || abort "! ip6tables - DNAT: Found"
  ui_print "- ip6tables - DNAT: Found"
  WGET_CMD=""
  if command -v wget >/dev/null 2>&1 && wget --help 2>&1 | grep -q -- "--no-check-certificate"; then
    WGET_CMD="wget"
  elif command -v busybox >/dev/null 2>&1 && busybox wget --help 2>&1 | grep -q -- "--no-check-certificate"; then
    WGET_CMD="busybox wget"
  elif [ -x /data/adb/magisk/busybox ] && /data/adb/magisk/busybox wget --help 2>&1 | grep -q -- "--no-check-certificate"; then
    WGET_CMD="/data/adb/magisk/busybox wget"
  elif [ -x /data/adb/ksu/bin/busybox ] && /data/adb/ksu/bin/busybox wget --help 2>&1 | grep -q -- "--no-check-certificate"; then
    WGET_CMD="/data/adb/ksu/bin/busybox wget"
  fi
  if [ -z "$WGET_CMD" ]; then
    abort "! wget: Not found"
  else
    ui_print "- wget: Found ($WGET_CMD)"
  fi
}
mkdir -p "$MODPATH"
echo "$WGET_CMD" > "$MODPATH/wgetpath"
binary_by_architecture() {
  ABI=$(grep_get_prop ro.product.cpu.abi)
  case "$ABI" in
    arm64-v8a)    BINARY="nfqws-aarch64"; BINARY2="dnscrypt-proxy-arm64" ;;
    x86_64)       BINARY="nfqws-x86_x64"; BINARY2="dnscrypt-proxy-x86_64" ;;
    armeabi-v7a)  BINARY="nfqws-arm";     BINARY2="dnscrypt-proxy-arm" ;;
    x86)          BINARY="nfqws-x86";     BINARY2="dnscrypt-proxy-i386" ;;
    *)            abort "! Unsupported Architecture: $ABI" ;;
  esac
  ui_print "- Device Architecture: $ABI"
  ui_print "- Binary (Zapret): $BINARY"
  ui_print "- Binary (DNSCrypt): $BINARY2"
}
check_requirements
binary_by_architecture
if [ -f "$MODPATH/uninstall.sh" ]; then
    "$MODPATH/uninstall.sh"
elif [ -f "$MODUPDATEPATH/uninstall.sh" ]; then
    "$MODUPDATEPATH/uninstall.sh"
fi
if [ -d "$MODUPDATEPATH" ]; then
  ui_print "- Updating module"
  cp -f "$MODPATH/wgetpath" "$MODUPDATEPATH/wgetpath"
  mkdir -p "$MODUPDATEPATH/list" "$MODUPDATEPATH/config"
  cp -f "$MODPATH/list/list-auto.txt" "$MODUPDATEPATH/list/list-auto.txt"
  cp -f "$MODPATH/list/list-exclude.txt" "$MODUPDATEPATH/list/list-exclude.txt"
  cp -f "$MODPATH/config/dnscrypt-enable" "$MODUPDATEPATH/config/dnscrypt-enable"
  cp -f "$MODPATH/config/dnscrypt-cloaking-update" "$MODUPDATEPATH/config/dnscrypt-cloaking-update"
  cp -f "$MODPATH/config/cloaking-rules-link" "$MODUPDATEPATH/config/cloaking-rules-link"
  cp -f "$MODPATH/config/dnscrypt-blocked-update" "$MODUPDATEPATH/config/dnscrypt-blocked-update"
  cp -f "$MODPATH/config/blocked-names-link" "$MODUPDATEPATH/config/blocked-names-link"
  if [ -f "$MODPATH/config/current-strategy" ]; then
    STRATEGY=$(cat "$MODPATH/config/current-strategy")
    STRATEGY_FILE="$MODUPDATEPATH/strategy/${STRATEGY}.sh"
    if [ -f "$STRATEGY_FILE" ]; then
      cp -f "$MODPATH/config/current-strategy" "$MODUPDATEPATH/config/current-strategy"
    else
      rm -f "$MODPATH/config/current-strategy"
    fi
  fi
fi
SCRIPT_DIRS="$MODPATH $MODUPDATEPATH $MODPATH/zapret $MODUPDATEPATH/zapret $MODPATH/strategy $MODUPDATEPATH/strategy $MODPATH/dnscrypt $MODUPDATEPATH/dnscrypt"
for DIR in $SCRIPT_DIRS; do
  for FILE in "$DIR"/*.sh; do
    [ -f "$FILE" ] && sed -i 's/\r$//' "$FILE"
  done
done
mv "$MODPATH/zapret/$BINARY" "$MODPATH/zapret/nfqws"
mv "$MODPATH/dnscrypt/$BINARY2" "$MODPATH/dnscrypt/dnscrypt-proxy"
mv "$MODUPDATEPATH/zapret/$BINARY" "$MODUPDATEPATH/zapret/nfqws"
mv "$MODUPDATEPATH/dnscrypt/$BINARY2" "$MODUPDATEPATH/dnscrypt/dnscrypt-proxy"
rm -f "$MODPATH/zapret/nfqws-"*
rm -f "$MODPATH/dnscrypt/dnscrypt-proxy-"*
rm -f "$MODUPDATEPATH/zapret/nfqws-"*
rm -f "$MODUPDATEPATH/dnscrypt/dnscrypt-proxy-"*
set_perm_recursive "$MODPATH" 0 2000 0755 0755
set_perm_recursive "$MODUPDATEPATH" 0 2000 0755 0755
ui_print "- Disabling Private DNS"
settings put global private_dns_mode off
ui_print "- Disabling Tethering Hardware Acceleration"
settings put global tether_offload_disabled 1
ui_print "* sevcator.t.me ! sevcator.github.io *"
if [ -d "$MODUPDATEPATH" ]; then
  ui_print "- Please reboot the device to continue use module"
fi
