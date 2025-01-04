
#!/system/bin/sh

MODID=zapret
MODPATH=/data/adb/modules/$MODID
MODUPDATEPATH=/data/adb/modules_update/$MODID

ui_print "- You're updating module from Magisk"

abort() {
  rmdir "$MODUPDATEPATH"
  rmdir "$MODPATH"
  exit 1
}

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

ui_print "- Fixing scripts syntax"
for FILE in "$MODPATH"/*.sh; do
  if [ -f "$FILE" ]; then
    sed -i 's/\r$//' "$FILE"
  fi
done

if [[ -f "$MODPATH/sevcator.sh" ]]; then
  . "$MODPATH/sevcator.sh"
else
  ui_print "- Error: sevcator.sh not found in $MODPATH"
  abort
fi

exit 0
