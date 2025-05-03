MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret

ui_print "- Mounting /data"
mount -o remount,rw /data || abort "! Failed to remount /data"

check_requirements() {
  command -v iptables >/dev/null 2>&1 || abort "! iptables: Not found"
  ui_print "- iptables: Found"

  command -v ip6tables >/dev/null 2>&1 || abort "! ip6tables: Not found"
  ui_print "- ip6tables: Found"
  
  grep -q 'NFQUEUE' /proc/net/ip_tables_targets || abort "! Bad iptables"
  grep -q 'NFQUEUE' /proc/net/ip6_tables_targets || abort "! Bad ip6tables"

  API=$(grep_get_prop ro.build.version.sdk)
  [ -n "$API" ] || abort "! Failed to detect Android API"
  ui_print "- Device Android API: $API"

  [ "$API" -ge 28 ] || abort "! Minimum required API 28 (Android 9)"
}

binary_by_architecture() {
  ABI=$(grep_get_prop ro.product.cpu.abi)
  case "$ABI" in
    arm64-v8a)    BINARY="nfqws-aarch64"; BINARY2="dnscrypt-proxy-arm64" ;;
    x86_64)       BINARY="nfqws-x86_x64"; BINARY2="dnscrypt-proxy-x86_64" ;;
    armeabi-v7a)  BINARY="nfqws-arm";     BINARY2="dnscrypt-proxy-arm" ;;
    x86)          BINARY="nfqws-x86";     BINARY2="dnscrypt-proxy-i386" ;;
    *)            abort "! Unsupported Architecture: $ABI" ;;
  esac
  ui_print "- Architecture: $ABI"
  ui_print "- Binary: $BINARY"
  ui_print "- DNSCrypt Binary: $BINARY2"
}

check_requirements
binary_by_architecture

if [ -f "$MODPATH/uninstall.sh" ]; then
    "$MODPATH/uninstall.sh"
elif [ -f "$MODUPDATEPATH/uninstall.sh" ]; then
    "$MODUPDATEPATH/uninstall.sh"
fi

backup_file() {
  src="$1"
  dst="$2"
  [ -f "$src" ] || return
  if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
    cp -f "$src" "$dst"
    ui_print "  > Backed up $(basename "$src")"
  fi
}

backup_old_files() {
  ui_print "- Backing up old files"
  mkdir -p "$MODUPDATEPATH/list" "$MODUPDATEPATH/config"

  backup_file "$MODPATH/list/list-auto.txt" "$MODUPDATEPATH/list/list-auto.txt"
  backup_file "$MODPATH/list/list-exclude.txt" "$MODUPDATEPATH/list/list-exclude.txt"
  backup_file "$MODPATH/config/current-plain-dns" "$MODUPDATEPATH/config/current-plain-dns"
  backup_file "$MODPATH/config/current-dns-mode" "$MODUPDATEPATH/config/current-dns-mode"

  if [ -f "$MODPATH/config/current-strategy" ]; then
    STRATEGY=$(cat "$MODPATH/config/current-strategy")
    STRATEGY_FILE="$MODUPDATEPATH/strategy/${STRATEGY}.sh"
    if [ -f "$STRATEGY_FILE" ]; then
      backup_file "$MODPATH/config/current-strategy" "$MODUPDATEPATH/config/current-strategy"
    else
      rm -f "$MODPATH/config/current-strategy"
      ui_print "  > Removed invalid strategy reference"
    fi
  fi

  if [ -d "$MODPATH/config" ]; then
    for src_file in "$MODPATH/config/"*; do
      [ -f "$src_file" ] || continue
      dst_file="$MODUPDATEPATH/config/$(basename "$src_file")"
      backup_file "$src_file" "$dst_file"
    done
  fi
}

SCRIPT_DIRS=(
  "$MODPATH"
  "$MODUPDATEPATH"
  "$MODPATH/zapret"
  "$MODUPDATEPATH/zapret"
  "$MODPATH/strategy"
  "$MODUPDATEPATH/strategy"
  "$MODPATH/dnscrypt"
  "$MODUPDATEPATH/dnscrypt"
)

for DIR in "${SCRIPT_DIRS[@]}"; do
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

ui_print "* sevcator.t.me / sevcator.github.io *"

if [ -d "$MODUPDATEPATH" ]; then
  ui_print "- Restart your device to continue using zapret"
fi
