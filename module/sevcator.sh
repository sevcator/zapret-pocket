# sevcator.github.io
MODID=zapret
MODPATH=/data/adb/modules/$MODID
MODUPDATEPATH=/data/adb/modules_update/$MODID

if [[ -d "$MODUPDATEPATH" ]]; then
  ui_print "- Moving update files to module directory"
  mkdir -p "$MODPATH"

  for file in "$MODUPDATEPATH"/*; do
    filename=$(basename "$file")

    if [[ -f "$file" && "$file" == *.txt ]]; then
      if [[ -f "$MODPATH/$filename" ]]; then
        size_update=$(stat -c%s "$file")
        size_existing=$(stat -c%s "$MODPATH/$filename")

        if [[ $size_update -gt $size_existing ]]; then
          ui_print "- Updating $filename"
          mv "$file" "$MODPATH"
        else
          rm "$MODPATH/$filename"
        fi
      else
        mv "$file" "$MODPATH"
      fi
    else
      mv "$file" "$MODPATH"
    fi
  done

  rmdir "$MODUPDATEPATH"
fi

abort() {
  rmdir "$MODUPDATEPATH"
  rmdir "$MODPATH"
  exit 1
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  cat $FILES 2>/dev/null | dos2unix | sed -n "$REGEX" | head -n 1
}

grep_get_prop() {
  local result=$(grep_prop $@)
  if [ -z "$result" ]; then
    # Fallback to getprop
    getprop "$1"
  else
    echo $result
  fi
}

check_requirements() {
  case "$ARCH" in
    arm)
      BINARY=nfqws-arm
      ;;
    arm64)
      BINARY=nfqws-aarch64
      ;;
    x86)
      BINARY=nfqws-x86
      ;;
    x86_64)
      BINARY=nfqws-x86_x64
      ;;
    *)
      ui_print "! Device Architecture: $ARCH"
      abort
      ;;
  esac
  ui_print "- Device Architecture: $ARCH"
  mv "$MODPATH/$BINARY" "$MODPATH/nfqws"
  rm "$MODPATH/nfqws-"*

  if [ -n "$API" ]; then
    ui_print "- Device Android API: $API"
    if [ "$API" -lt 27 ]; then
      ui_print "! Device Android API: required 27 (Android 7.1)"
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
}

check_requirements

rm -rf "$MODPATH/update"
rm -rf "$MODPATH/skip_mount"
rm -rf "$MODPATH/remove"
rm -rf "$MODPATH/disable"

# The steps of installing module (Main part)
ui_print "- Removing unnecessary files"
rm -rf "$MODPATH/customize.sh"
rm -rf "$MODPATH/sevcator.sh"

ui_print "- Setting permissions"
for FILE in "$MODPATH"/*; do
  if [ -f "$FILE" ]; then
    chmod 755 "$FILE"
    chown root:root "$FILE"
  fi
done

ui_print "********************************************************"
ui_print "       THIS MODULE IS FOR EDUCATIONAL PURPOSES!"
ui_print "    THE OWNER IS NOT RESPONSIBLE FOR YOUR ACTIONS!"
ui_print "********************************************************"
ui_print "**         sevcator.t.me / sevcator.github.io         **"
ui_print "**          Please leave a star on GitHub !!          **"
