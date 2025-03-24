# Variables
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
  case $ABI in
    arm64-v8a) BINARY=nfqws-aarch64 ;;
    x86_64) BINARY=nfqws-x86_x64 ;;
    armeabi-v7a) BINARY=nfqws-arm ;;
    x86) BINARY=nfqws-x86 ;;
    *) abort "! Unsupported Architecture: $ABI" ;;
  esac
  ui_print "- Device architecture: $ABI"
  ui_print "- Binary: $BINARY"
}

ui_print "- Checking requirements"
check_requirements
ui_print "- Choosing the binary by device architecture"
binary_by_architecture

ui_print "- Terminating processes"
for pid in $(pgrep -f zapret.sh); do
    kill -9 $pid
done
pkill nfqws
pkill zapret

ui_print "- Cleaning iptables rules"
iptables -t mangle -F POSTROUTING
iptables -t mangle -F PREROUTING
iptables -F OUTPUT
iptables -F FORWARD
iptables -t nat -F OUTPUT
iptables -t nat -F PREROUTING

ui_print "- Cleaning ip6tables rules"
ip6tables -t mangle -F POSTROUTING
ip6tables -t mangle -F PREROUTING
ip6tables -F OUTPUT
ip6tables -F FORWARD

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

    if [ -f "$MODPATH/current-dns" ]; then
        mv "$MODPATH/current-dns" "$MODUPDATEPATH/current-dns"
    fi

    mkdir -p "$MODPATH"
    cp -rf "$MODUPDATEPATH"/* "$MODPATH"/
    rm -rf "$MODUPDATEPATH"
fi

ui_print "- Fixing syntax error in bash scripts"
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

ui_print "- Fixing Chrome problem @ t.me/sevcator/883"
if [ ! -f "$MODPATH/list-auto.txt" ]; then
    touch "$MODPATH/list-auto.txt"
fi
REQUIRED_DOMAINS="www.google.com google.com connectivitycheck.gstatic.com"
for DOMAIN in $REQUIRED_DOMAINS; do
    if ! grep -qi "^$DOMAIN$" "$MODPATH/list-auto.txt"; then
        echo "$DOMAIN" >> "$MODPATH/list-auto.txt"
    fi
done

mv "$MODPATH/$BINARY" "$MODPATH/nfqws" 2>/dev/null || abort "! Binary not found"
rm -f "$MODPATH/nfqws-"*
if [ ! -f "$MODPATH/nfqws" ]; then
  abort "! Binary not found (2)"
fi

ui_print "- Setting permissions"
set_perm_recursive "$MODPATH" 0 2000 0755 0755

ui_print "- Disabling Private DNS"
settings put global private_dns_mode off

ui_print "- Disabling Tethering Hardware Acceleration"
settings put global tether_offload_disabled 1
