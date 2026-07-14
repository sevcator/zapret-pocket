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
  arm64-v8a)    BINARY="nfqws-aarch64"; BINARY_NFQWS2="nfqws2-aarch64"; BINARY2="dnscrypt-proxy-arm64"; BINARY3="curl-aarch64" ;;
  x86_64)       BINARY="nfqws-x86_x64"; BINARY_NFQWS2="nfqws2-x86_x64"; BINARY2="dnscrypt-proxy-x86_64"; BINARY3="curl-x86_64" ;;
  armeabi-v7a)  BINARY="nfqws-arm";     BINARY_NFQWS2="nfqws2-arm";     BINARY2="dnscrypt-proxy-arm";     BINARY3="curl-arm" ;;
  x86)          BINARY="nfqws-x86";     BINARY_NFQWS2="nfqws2-x86";     BINARY2="dnscrypt-proxy-i386";    BINARY3="curl-x86" ;;
  *)            abort "! Unsupported architecture: $ABI" ;;
esac
ui_print "- Device architecture: $ABI"

preserve_user_data_for_update() {
  [ -d "$MODUPDATEPATH" ] || return 0
  [ -d "$FINALMODPATH" ] || return 0

  mkdir -p "$MODUPDATEPATH/config" "$MODUPDATEPATH/list"

  cp -af "$FINALMODPATH/config/." "$MODUPDATEPATH/config/" 2>/dev/null || true
  cp -af "$FINALMODPATH/list/list-general-user.txt" "$MODUPDATEPATH/list/list-general-user.txt" 2>/dev/null || true
  cp -af "$FINALMODPATH/list/list-exclude-user.txt" "$MODUPDATEPATH/list/list-exclude-user.txt" 2>/dev/null || true
  cp -af "$FINALMODPATH/list/ipset-all-user.txt" "$MODUPDATEPATH/list/ipset-all-user.txt" 2>/dev/null || true
  cp -af "$FINALMODPATH/list/ipset-exclude-user.txt" "$MODUPDATEPATH/list/ipset-exclude-user.txt" 2>/dev/null || true
  cp -af "$FINALMODPATH/list/ipset-wssize-user.txt" "$MODUPDATEPATH/list/ipset-wssize-user.txt" 2>/dev/null || true

  # User overlays for the dnscrypt lists (cloaking / blocked-names / blocked-ips)
  mkdir -p "$MODUPDATEPATH/dnscrypt"
  cp -af "$FINALMODPATH/dnscrypt/cloaking-rules-user.txt" "$MODUPDATEPATH/dnscrypt/cloaking-rules-user.txt" 2>/dev/null || true
  cp -af "$FINALMODPATH/dnscrypt/blocked-names-user.txt" "$MODUPDATEPATH/dnscrypt/blocked-names-user.txt" 2>/dev/null || true
  cp -af "$FINALMODPATH/dnscrypt/blocked-ips-user.txt" "$MODUPDATEPATH/dnscrypt/blocked-ips-user.txt" 2>/dev/null || true

}
preserve_user_data_for_update

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
else
  # Android 9+ requires `pm install` to read the APK from a location the system
  # PackageManager can access under enforcing SELinux. The module staging dir is
  # not readable by system_server, so copy the APK into /data/local/tmp first.
  APKTMP="/data/local/tmp/VpnHotspot-install.apk"
  cp -f "$APKPATH" "$APKTMP" 2>/dev/null
  chmod 0644 "$APKTMP" 2>/dev/null
  chcon u:object_r:shell_data_file:s0 "$APKTMP" 2>/dev/null || true
  if pm install "$APKTMP" >/dev/null 2>&1; then
    ui_print "- VpnHotspot installed"
    rm -f "$APKTMP"
    rm -rf "$(dirname "$APKPATH")"
  else
    ui_print "! VpnHotspot installation failed (incompatible Android version?)"
    rm -f "$APKTMP"
    # Leave the APK under system/app as a systemized fallback for the boot scan.
  fi
fi

ui_print "- Disabling Private DNS"
settings put global private_dns_mode off >/dev/null 2>&1 || true

ui_print "- Disabling tether offload"
settings put global tether_offload_disabled 1 >/dev/null 2>&1 || true

sanitize_scripts() {
  SCRIPT_DIRS="$MODPATH $ZAPRET_DIR $STRATEGY_DIR $DNSCRYPT_DIR $CONFIG_DIR $LIST_DIR $MODPATH/system/bin"
  for DIR in $SCRIPT_DIRS; do
    for FILE in "$DIR"/*.sh "$DIR"/zapret; do
      [ -f "$FILE" ] && sed -i 's/\r$//' "$FILE"
    done
  done
}
sanitize_scripts

prepare_binaries() {
  [ -f "$ZAPRET_DIR/$BINARY" ] || abort "! Missing zapret binary: $ZAPRET_DIR/$BINARY"
  [ -f "$DNSCRYPT_DIR/$BINARY2" ] || abort "! Missing dnscrypt binary: $DNSCRYPT_DIR/$BINARY2"
  [ -f "$MODPATH/$BINARY3" ] || abort "! Missing curl binary: $MODPATH/$BINARY3"
  mv "$ZAPRET_DIR/$BINARY" "$ZAPRET_DIR/nfqws"
  mv "$DNSCRYPT_DIR/$BINARY2" "$DNSCRYPT_DIR/dnscrypt-proxy"
  mv "$MODPATH/$BINARY3" "$MODPATH/curl"

  # zapret2 engine (nfqws2). Optional: ZAPRET=1 strategies still work without it,
  # so a missing nfqws2 is a warning, not a fatal abort.
  if [ -f "$ZAPRET_DIR/$BINARY_NFQWS2" ]; then
    mv "$ZAPRET_DIR/$BINARY_NFQWS2" "$ZAPRET_DIR/nfqws2"
    ui_print "- zapret2 engine: installed (nfqws2)"
  else
    ui_print "! zapret2 engine (nfqws2) not bundled — ZAPRET=2 strategies will be unavailable"
  fi

  rm -f "$ZAPRET_DIR/nfqws-"*
  rm -f "$ZAPRET_DIR/nfqws2-"*
  rm -f "$DNSCRYPT_DIR/dnscrypt-proxy-"*
  rm -f "$MODPATH"/curl-*
}
prepare_binaries

set_perm_recursive "$MODPATH" 0 2000 0755 0755
ui_print "* sevcator.t.me | sevcator.github.io *"
