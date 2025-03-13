# Variables
MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret
SYSTEM_XBIN=$MODULE_DIR/system/xbin
BUSYBOX_PATH=/data/adb/magisk/busybox

# Mount /data
mount /data 2>/dev/null

# Check requirements
check_requirements() {
  API=$(grep_get_prop ro.build.version.sdk)
  if [ -n "$API" ]; then
    ui_print "- Device Android API: $API"
    if [ "$API" -lt 28 ]; then
      abort "! Minimum required API 28 (Android 9)"
    fi
  else
    abort "! Failed to detect Android API"
  fi

  if command -v iptables >/dev/null 2>&1; then
    ui_print "- iptables: Found"
  else
    abort "! iptables not found"
  fi

  if [ "$(cat /proc/net/ip_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    ui_print "! Bad iptables"
    abort
  fi

    if [ "$(cat /proc/net/ip_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    abort "! Incompatible iptables version"
  fi

  if ! command -v busybox >/dev/null 2>&1; then
    ui_print "- Busybox: Not found, will install"
    BUSYBOX_REQUIRED=1
  fi
}

# Get binary to use from device architecture
binary_by_architecture() {
  ABI=$(grep_get_prop ro.product.cpu.abi)
  case $ABI in
    arm64-v8a) BINARY=nfqws-aarch64 ;;
    x86_64) BINARY=nfqws-x86_x64 ;;
    armeabi-v7a) BINARY=nfqws-arm ;;
    x86) BINARY=nfqws-x86 ;;
    *) abort "! Unsupported Architecture: $ABI" ;;
  esac
  ui_print "- Device Architecture: $ABI"
}

check_requirements
binary_by_architecture

# Kill watchdog and zapret
for pid in $(pgrep -f zapret.sh); do
    kill -9 $pid
done
pkill nfqws
pkill zapret
iptables -t mangle -F PREROUTING
iptables -t mangle -F POSTROUTING

# Save files if module is updating
if [ -d "$MODUPDATEPATH" ]; then
    ui_print "- Updating the module"

    if [ -f "$MODPATH/list-auto.txt" ]; then
        mv "$MODPATH/list-auto.txt" "$MODUPDATEPATH/list-auto.txt"
    fi

    if [ -f "$MODPATH/current-tactic" ]; then
        TACTIC=$(cat "$MODPATH/current-tactic")
        TACTIC_FILE="$MODUPDATEPATH/tactics/${TACTIC}.sh"
        if [ -f "$TACTIC_FILE" ]; then
            mv "$MODPATH/current-tactic" "$MODUPDATEPATH/current-tactic"
        fi
    fi

    rm -rf "$MODPATH"
    mv "$MODUPDATEPATH" "$MODPATH"
fi

# Install Busybox if need (only Magisk users)
if [ "$BUSYBOX_REQUIRED" -eq 1 ] && [ ! -f "$BUSYBOX_PATH" ]; then
    ui_print "- Installing Busybox"

    if ! mkdir -p "$SYSTEM_XBIN"; then
        abort "! Failed creating folder"
    fi
    
    if ! cp "$BUSYBOX_PATH" "$SYSTEM_XBIN/"; then
        abort "! Failed copying binary"
    fi

    set_perm_recursive "$SYSTEM_XBIN" 0 2000 0755 0755
fi

for FILE in "$MODPATH"/*.sh; do
  if [[ -f "$FILE" ]]; then
    sed -i 's/\r$//' "$FILE"
  fi
done

for FILE in "$MODPATH/tactics/"*.sh; do
  if [[ -f "$FILE" ]]; then
    sed -i 's/\r$//' "$FILE"
  fi
done

# Final steps
mv "$MODPATH/$BINARY" "$MODPATH/nfqws"
rm -f "$MODPATH/nfqws-"*
set_perm_recursive $MODPATH 0 2000 0755 0755

settings put global private_dns_mode off

ui_print "********************************************************"
ui_print "       THIS MODULE IS FOR EDUCATIONAL PURPOSES!"
ui_print "    THE OWNER IS NOT RESPONSIBLE FOR YOUR ACTIONS!"
ui_print "********************************************************"
ui_print "           github.com/sevcator/zapret-magisk            "
ui_print "********************************************************"
