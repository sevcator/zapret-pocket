#!/system/bin/sh

MODPATH="${MODPATH:-$PWD}"
FINALMODPATH="/data/adb/modules/zapret"
MODUPDATEPATH="/data/adb/modules_update/zapret"
APKMODPATH="$MODPATH/system/app/VpnHotspot.apk"
APKPATH="$APKMODPATH"
PACKAGENAME="be.mygod.vpnhotspot"
COMMON_SH=""

ui_print "- Mounting /data"
mount -o remount,rw /data >/dev/null 2>&1 || true

if [ -f "$MODUPDATEPATH/common.sh" ]; then
  COMMON_SH="$MODUPDATEPATH/common.sh"
elif [ -f "$MODPATH/common.sh" ]; then
  COMMON_SH="$MODPATH/common.sh"
elif [ -f "./common.sh" ]; then
  COMMON_SH="./common.sh"
else
  abort "! common.sh not found"
fi

. "$COMMON_SH"

command -v iptables >/dev/null 2>&1 || abort "! iptables: Not found"
ui_print "- iptables: Found"

HAS_IP6TABLES=1
if command -v ip6tables >/dev/null 2>&1; then
  ui_print "- ip6tables: Found"
else
  ui_print "! ip6tables: Not found, IPv6 features will be skipped"
  HAS_IP6TABLES=0
fi

grep -q 'NFQUEUE' /proc/net/ip_tables_targets || abort "! iptables NFQUEUE: Not found"
ui_print "- iptables NFQUEUE: Found"

if [ "$HAS_IP6TABLES" = "1" ]; then
  grep -q 'NFQUEUE' /proc/net/ip6_tables_targets || ui_print "! ip6tables NFQUEUE: Not found, IPv6 interception disabled"
fi

ABI="$(grep_get_prop ro.product.cpu.abi)"
case "$ABI" in
  arm64-v8a)    BINARY="nfqws-aarch64"; BINARY2="dnscrypt-proxy-arm64"; BINARY3="curl-aarch64" ;;
  x86_64)       BINARY="nfqws-x86_x64"; BINARY2="dnscrypt-proxy-x86_64"; BINARY3="curl-x86_64" ;;
  armeabi-v7a)  BINARY="nfqws-arm";     BINARY2="dnscrypt-proxy-arm";     BINARY3="curl-arm" ;;
  x86)          BINARY="nfqws-x86";     BINARY2="dnscrypt-proxy-i386";    BINARY3="curl-x86" ;;
  *)            abort "! Unsupported architecture: $ABI" ;;
esac
ui_print "- Device architecture: $ABI"

import_updated_lists() {
  [ -d "$MODUPDATEPATH" ] || return 0
  mkdir -p "$CONFIG_DIR" "$LIST_DIR"
  cp -af "$MODUPDATEPATH/config/." "$CONFIG_DIR/" 2>/dev/null || true
  cp -af "$MODUPDATEPATH/list/." "$LIST_DIR/" 2>/dev/null || true
  cp -af "$MODUPDATEPATH/lists/." "$LIST_DIR/" 2>/dev/null || true
  cp -af "$MODUPDATEPATH/ipset/." "$IPSET_DIR/" 2>/dev/null || true
}
import_updated_lists

if pm list packages | grep -q "$PACKAGENAME"; then
  ui_print "- VpnHotspot is already installed"
  rm -rf "$(dirname "$APKPATH")"
elif pm install "$APKPATH" >/dev/null 2>&1; then
  ui_print "- VpnHotspot installed"
  rm -rf "$(dirname "$APKPATH")"
else
  ui_print "! VpnHotspot installation failed"
fi

ui_print "- Disabling Private DNS"
settings put global private_dns_mode off >/dev/null 2>&1 || true

ui_print "- Disabling tether offload"
settings put global tether_offload_disabled 1 >/dev/null 2>&1 || true

sanitize_scripts() {
  SCRIPT_DIRS="$MODPATH $STRATEGY_DIR $DNSCRYPT_DIR $CONFIG_DIR $LIST_DIR $MODPATH/system/bin"
  for DIR in $SCRIPT_DIRS; do
    for FILE in "$DIR"/*.sh "$DIR"/zapret; do
      [ -f "$FILE" ] && sed -i 's/\r$//' "$FILE"
    done
  done
}
sanitize_scripts

prepare_binaries() {
  [ -f "$STRATEGY_DIR/$BINARY" ] || abort "! Missing zapret binary: $STRATEGY_DIR/$BINARY"
  [ -f "$DNSCRYPT_DIR/$BINARY2" ] || abort "! Missing dnscrypt binary: $DNSCRYPT_DIR/$BINARY2"
  [ -f "$MODPATH/$BINARY3" ] || abort "! Missing curl binary: $MODPATH/$BINARY3"
  mv "$STRATEGY_DIR/$BINARY" "$STRATEGY_DIR/nfqws"
  mv "$DNSCRYPT_DIR/$BINARY2" "$DNSCRYPT_DIR/dnscrypt-proxy"
  mv "$MODPATH/$BINARY3" "$MODPATH/curl"
  rm -f "$STRATEGY_DIR/nfqws-"*
  rm -f "$DNSCRYPT_DIR/dnscrypt-proxy-"*
  rm -f "$MODPATH"/curl-*
}
prepare_binaries

set_perm_recursive "$MODPATH" 0 2000 0755 0755
ui_print "* sevcator.t.me | sevcator.github.io *"
