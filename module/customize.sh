MODPATH="/data/adb/modules/zapret"
MODUPDATEPATH="/data/adb/modules_update/zapret"
APKMODPATH="$MODPATH/system/app/VpnHotspot.apk"
PACKAGENAME="be.mygod.vpnhotspot"
ui_print "- Mounting /data"
mount -o remount,rw /data
check_requirements() {
  command -v iptables >/dev/null 2>&1 || abort "! iptables: Not found"
  ui_print "- iptables: Found"
  HAS_IP6TABLES=1
  if command -v ip6tables >/dev/null 2>&1; then
    ui_print "- ip6tables: Found"
  else
    ui_print "! ip6tables: Not found, IPv6 features will be skipped"
    HAS_IP6TABLES=0
  fi
  grep -q 'NFQUEUE' /proc/net/ip_tables_targets || abort "! iptables - NFQUEUE: Not found"
  ui_print "- iptables - NFQUEUE: Found"
  if [ "$HAS_IP6TABLES" = 1 ]; then
    grep -q 'NFQUEUE' /proc/net/ip6_tables_targets || abort "! ip6tables - NFQUEUE: Not found"
    ui_print "- ip6tables - NFQUEUE: Found"
  fi
  grep -q 'DNAT' /proc/net/ip_tables_targets || abort "! iptables - DNAT: Not found"
  ui_print "- iptables - DNAT: Found"
  if [ "$HAS_IP6TABLES" = 1 ]; then
    grep -q 'DNAT' /proc/net/ip6_tables_targets || abort "! ip6tables - DNAT: Not found"
    ui_print "- ip6tables - DNAT: Found"
  fi
}
binary_by_architecture() {
  ABI=$(grep_get_prop ro.product.cpu.abi)
  case "$ABI" in
    arm64-v8a)    BINARY="nfqws-aarch64"; BINARY2="dnscrypt-proxy-arm64"; BINARY3="curl-aarch64" ;;
    x86_64)       BINARY="nfqws-x86_x64"; BINARY2="dnscrypt-proxy-x86_64"; BINARY3="curl-x86_64" ;;
    armeabi-v7a)  BINARY="nfqws-arm";     BINARY2="dnscrypt-proxy-arm";     BINARY3="curl-arm" ;;
    x86)          BINARY="nfqws-x86";     BINARY2="dnscrypt-proxy-i386";    BINARY3="curl-x86" ;;
    *)            abort "! Unsupported Architecture: $ABI" ;;
  esac
  ui_print "- Device Architecture: $ABI"
  ui_print "- Binary (Zapret): $BINARY"
  ui_print "- Binary (DNSCrypt): $BINARY2"
  ui_print "- Binary (curl): $BINARY3"
}
import_updated_lists() {
  [ -d "$MODUPDATEPATH" ] || return 0
  mkdir -p "$MODPATH/config" "$MODPATH/list"
  cp -af "$MODUPDATEPATH/config/." "$MODPATH/config/" 2>/dev/null
  cp -af "$MODUPDATEPATH/list/." "$MODPATH/list/" 2>/dev/null
}
install_tethering_app() {
  APKPATH="$1"
  if pm list packages | grep -q "$PACKAGENAME"; then
    ui_print "- Tethering app already installed"
    rm -rf "$(dirname "$APKPATH")"
    return
  fi
  if pm install "$APKPATH" > /dev/null 2>&1; then
    ui_print "- pm install completed"
  else
    ui_print "! pm install failed"
  fi
  if pm list packages | grep -q "$PACKAGENAME"; then
    ui_print "- Tethering app already installed"
    rm -rf "$(dirname "$APKPATH")"
    return
  else
    API=$(getprop ro.build.version.sdk)
    if [ -n "$API" ]; then
      if [ "$API" -gt 30 ]; then
        ui_print "! Device Android API: $API => 30"
        ui_print "! The app will not be pre-installed"
      elif [ "$API" -lt 25 ]; then
        ui_print "! Device Android API: $API <= 25"
        ui_print "! The app will not be pre-installed"
      else
        ui_print "- Device Android API: $API"
        ui_print "- The app will be pre-installed"
      fi
    else
      ui_print "! Failed to detect Android API"
    fi
    rm -rf "$(dirname "$APKPATH")"
  fi
}
SCRIPT_DIRS="$MODPATH $MODPATH/zapret $MODPATH/dnscrypt $MODPATH/config $MODPATH/list"
for DIR in $SCRIPT_DIRS; do
  for FILE in "$DIR"/*.sh; do
    [ -f "$FILE" ] && sed -i 's/\r$//' "$FILE"
  done
done
if [ -f "$MODPATH/uninstall.sh" ]; then
  "$MODPATH/uninstall.sh"
fi
check_requirements
binary_by_architecture
mkdir -p "$MODPATH"
import_updated_lists
ui_print "- Installing tethering app"
install_tethering_app "$APKMODPATH"
mv "$MODPATH/zapret/$BINARY" "$MODPATH/zapret/nfqws"
mv "$MODPATH/dnscrypt/$BINARY2" "$MODPATH/dnscrypt/dnscrypt-proxy"
mv "$MODPATH/$BINARY3" "$MODPATH/curl"
rm -f "$MODPATH/zapret/nfqws-"*
rm -f "$MODPATH/dnscrypt/dnscrypt-proxy-"*
rm -f "$MODPATH/curl-"*
set_perm_recursive "$MODPATH" 0 2000 0755 0755
ui_print "- Disabling Private DNS"
settings put global private_dns_mode off
ui_print "- Disabling Tethering Hardware Acceleration"
settings put global tether_offload_disabled 1
ui_print "* sevcator.t.me ! sevcator.github.io *"
ui_print "* Ã£â€šÂµÃ£Æ’ÂÃ£Æ’Â¼Ã£Æ’Ë†Ã£Ââ€šÃ£â€šÅ Ã£ÂÅ’Ã£ÂÂ¨Ã£Ââ€ Ã£Ââ€Ã£Ââ€“Ã£Ââ€žÃ£ÂÂ¾Ã£Ââ„¢!!"
