#!/system/bin/sh

ACTION="$1"
MODPATH="/data/adb/modules/zapret"
CLOAKING_RULES="$MODPATH/dnscrypt/cloaking-rules.txt"
CUSTOM_RULES="$MODPATH/dnscrypt/custom-cloaking-rules.txt"

append() {
  grep -Fxq "# custom hosts" "$CLOAKING_RULES" && return
  [ -s "$CLOAKING_RULES" ] && [ "$(tail -c1 "$CLOAKING_RULES")" != $'\n' ] && echo "" >> "$CLOAKING_RULES"
  {
    echo "# custom hosts"
    cat "$CUSTOM_RULES"
  } >> "$CLOAKING_RULES"
}

disappend() {
  awk '
    BEGIN { skip = 0 }
    /^# custom hosts/ { skip = 1; next }
    /^#/ && skip { skip = 0 }
    !skip
  ' "$CLOAKING_RULES" > "$CLOAKING_RULES.tmp" && mv "$CLOAKING_RULES.tmp" "$CLOAKING_RULES"
}

case "$ACTION" in
  append) append ;;
  disappend) disappend ;;
  *) echo "Usage: $0 append|disappend"; exit 1 ;;
esac
