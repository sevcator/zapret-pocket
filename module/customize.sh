MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret
SYSTEM_XBIN=$MODULE_DIR/system/xbin
BUSYBOX_PATH=/data/adb/magisk/busybox

check_requirements() {
  ABI=$(grep_get_prop ro.product.cpu.abi)
  if [ "$ABI" = "arm64-v8a" ]; then
    BINARY=nfqws-aarch64
  elif [ "$ABI" = "x86_64" ]; then
    BINARY=nfqws-x86_x64
  elif [ "$ABI" = "armeabi-v7a" ]; then
    BINARY=nfqws-arm
  elif [ "$ABI" = "x86" ]; then
    BINARY=nfqws-x86
  else
    ui_print "! Invaild Device Architecture"
    abort
  fi
  ui_print "- Device Architecture: $ABI"

  API=$(grep_get_prop ro.build.version.sdk)
  if [ -n "$API" ]; then
    ui_print "- Device Android API: $API"
    if [ "$API" -lt 28 ]; then
      ui_print "! Device Android API: At least required 28 (Android 9)"
      abort
    fi
  else
    ui_print "! Device Android API: Error"
    exit 1
  fi

  if which iptables > /dev/null 2>&1; then
    ui_print "- iptables: Installed"
  else
    ui_print "! iptables: Not found"
    abort
  fi

  if [ "$(cat /proc/net/ip_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    ui_print "! Bad iptables"
    abort
  fi

  if which busybox > /dev/null 2>&1; then
    ui_print "- Busybox: Installed"
  else
    ui_print "! Busybox: Not found"
    BUSYBOX_REQUIRED=1
  fi
}

check_requirements

for pid in $(pgrep -f zapret.sh); do
    kill -9 $pid
done
su -c 'pkill nfqws'
su -c 'pkill zapret'
su -c 'iptables -t mangle -F PREROUTING'
su -c 'iptables -t mangle -F POSTROUTING'

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

mv "$MODPATH/$BINARY" "$MODPATH/nfqws"
rm -f "$MODPATH/nfqws-"*

set_perm_recursive $MODPATH 0 2000 0755 0755
settings put global private_dns_mode off
ui_print "- The Private DNS has been disabled, if you need enable them, turn it back"

ui_print "********************************************************"
ui_print "       THIS MODULE IS FOR EDUCATIONAL PURPOSES!"
ui_print "    THE OWNER IS NOT RESPONSIBLE FOR YOUR ACTIONS!"
ui_print "********************************************************"
ui_print "           github.com/sevcator/zapret-magisk            "
ui_print "********************************************************"
