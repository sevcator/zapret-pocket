# If you don't know what you're doing, don't touch anything

MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret

check_requirements() {
  ABI=$(grep_get_prop ro.product.cpu.abi)
  case "$ABI" in
    arm64-v8a)
      BINARY=nfqws-aarch64
      ;;
    x86)
      BINARY=nfqws-x86
      ;;
    x86_64)
      BINARY=nfqws-x86_x64
      ;;
    *)
      ABI=armeabi-v7a
      BINARY=nfqws-arm
      ;;
  esac
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

  if which busybox > /dev/null 2>&1; then
    ui_print "- Busybox: Installed"
  else
    ui_print "! Busybox: Not found"
    abort
  fi

  if which iptables > /dev/null 2>&1; then
    ui_print "- iptables: Installed"
  else
    ui_print "! iptables: Not found"
    abort
  fi
}

check_requirements

mv "$MODPATH/$BINARY" "$MODPATH/nfqws"
rm "$MODPATH/nfqws-"*
mv "$MODUPDATEPATH/$BINARY" "$MODUPDATEPATH/nfqws"
rm "$MODUPDATEPATH/nfqws-"*
rm -rf "$MODPATH/update"
rm -rf "$MODPATH/skip_mount"
rm -rf "$MODPATH/remove"
rm -rf "$MODPATH/disable"
rm -rf "$MODPATH/customize.sh"
rm -rf "$MODPATH/sevcator.sh"
rm -rf "$MODPATH/google.txt"

set_perm_recursive $MODPATH 0 2000 0755 0755
set_perm_recursive $MODUPDATEPATH 0 2000 0755 0755

for FILE in "$MODPATH"/*.txt; do
  if [ -f "$FILE" ]; then
    BASE_FILE="$MODUPDATEPATH/$(basename "$FILE")"
    if [ -f "$BASE_FILE" ]; then
      FILE_SIZE=$(stat -c%s "$FILE")
      BASE_FILE_SIZE=$(stat -c%s "$BASE_FILE")
      if [ "$FILE_SIZE" -gt "$BASE_FILE_SIZE" ]; then
        rm "$BASE_FILE"
        if [ ! -f "$FILE" ]; then
          ui_print "! Failed to delete $BASE_FILE"
        fi
      fi
    fi
  fi
done

if [[ -d "$MODUPDATEPATH" ]]; then
  ui_print "- Seems you update the module ^_^"
fi

ui_print "********************************************************"
ui_print "       THIS MODULE IS FOR EDUCATIONAL PURPOSES!"
ui_print "    THE OWNER IS NOT RESPONSIBLE FOR YOUR ACTIONS!"
ui_print "********************************************************"
ui_print "**         sevcator.t.me / sevcator.github.io         **"
ui_print "**          Please leave a star on GitHub !!          **"
