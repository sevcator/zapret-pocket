MODPATH="/data/adb/modules/zapret"
MODUPDATEPATH="/data/adb/modules_update/zapret"
APKMODPATH="$MODPATH/system/app/VpnHotspot.apk"
APKMODUPDATEPATH="$MODUPDATEPATH/system/app/VpnHotspot.apk"
PACKAGENAME="be.mygod.vpnhotspot"
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
  grep -q 'DNAT' /proc/net/ip_tables_targets || abort "! iptables - DNAT: Not found"
  ui_print "- iptables - DNAT: Found"
  grep -q 'DNAT' /proc/net/ip6_tables_targets || abort "! ip6tables - DNAT: Not found"
  ui_print "- ip6tables - DNAT: Found"
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
SCRIPT_DIRS="$MODPATH $MODUPDATEPATH $MODPATH/zapret $MODUPDATEPATH/zapret $MODPATH/strategy $MODUPDATEPATH/strategy $MODPATH/dnscrypt $MODUPDATEPATH/dnscrypt $MODPATH/config $MODUPDATEPATH/config"
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
if [ -d "$MODUPDATEPATH" ]; then
  cp -an "$MODPATH/strategy/"* "$MODUPDATEPATH/strategy/"
  ui_print "- Backing up old files"
  rm -rf "$MODPATH/.old_files"
  mkdir -p "$MODUPDATEPATH/.old_files"
  cp -a "$MODPATH/"* "$MODUPDATEPATH/.old_files/" 2>/dev/null
  ui_print "- Updating module"
  cp -f "$MODPATH/config" "$MODUPDATEPATH/config"
  cp -f "$MODPATH/dnscrypt/custom-cloaking-rules.txt" "$MODUPDATEPATH/dnscrypt/custom-cloaking-rules.txt"
  cp -f "$MODPATH/list/exclude.txt" "$MODUPDATEPATH/list/exclude.txt"
  cp -f "$MODPATH/ipset/exclude.txt" "$MODUPDATEPATH/ipset/exclude.txt"
  cp -f "$MODPATH/list/custom.txt" "$MODUPDATEPATH/list/custom.txt"
  cp -f "$MODPATH/ipset/custom.txt" "$MODUPDATEPATH/ipset/custom.txt"
  ui_print "- Installing tethering app"
  install_tethering_app "$APKMODUPDATEPATH"
  mv "$MODUPDATEPATH/zapret/$BINARY" "$MODUPDATEPATH/zapret/nfqws"
  mv "$MODUPDATEPATH/dnscrypt/$BINARY2" "$MODUPDATEPATH/dnscrypt/dnscrypt-proxy"
  mv "$MODUPDATEPATH/$BINARY3" "$MODUPDATEPATH/curl"
  rm -f "$MODUPDATEPATH/zapret/nfqws-"*
  rm -f "$MODUPDATEPATH/dnscrypt/dnscrypt-proxy-"*
  rm -f "$MODUPDATEPATH/curl-"*
  set_perm_recursive "$MODUPDATEPATH" 0 2000 0755 0755
else
  ui_print "- Installing tethering app"
  install_tethering_app "$APKMODPATH"
  mv "$MODPATH/zapret/$BINARY" "$MODPATH/zapret/nfqws"
  mv "$MODPATH/dnscrypt/$BINARY2" "$MODPATH/dnscrypt/dnscrypt-proxy"
  mv "$MODPATH/$BINARY3" "$MODPATH/curl"
  rm -f "$MODPATH/zapret/nfqws-"*
  rm -f "$MODPATH/dnscrypt/dnscrypt-proxy-"*
  rm -f "$MODPATH/curl-"*
  set_perm_recursive "$MODPATH" 0 2000 0755 0755
fi
ui_print "- Disabling Private DNS"
settings put global private_dns_mode off
ui_print "- Disabling Tethering Hardware Acceleration"
settings put global tether_offload_disabled 1
ui_print "* sevcator.t.me ! sevcator.github.io *"
ui_print "* サポートありがとうございます!!"
if [ -d "$MODUPDATEPATH" ]; then
  ui_print "- Please reboot the device to continue use module"
fi
