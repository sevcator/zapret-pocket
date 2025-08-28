#!/system/bin/sh
set -e

MODPATH=/data/adb/modules/zapret
CLOAKING_RULES=$MODPATH/dnscrypt/cloaking-rules.txt
CUSTOM_RULES=$MODPATH/dnscrypt/custom-cloaking-rules.txt

ensure_newline() {
  [ -f "$1" ] || return
  [ -s "$1" ] || return
  [ "$(tail -c1 "$1")" = "" ] && return
  printf "\n" >> "$1"
}

append() {
  [ -f "$CUSTOM_RULES" ] || return 1
  grep -Fxq "# custom hosts" "$CLOAKING_RULES" 2>/dev/null && return 0

  mkdir -p "$(dirname "$CLOAKING_RULES")"
  touch "$CLOAKING_RULES"
  ensure_newline "$CLOAKING_RULES"

  {
    printf "\n"
    printf "# custom hosts\n"
    cat "$CUSTOM_RULES"
  } >> "$CLOAKING_RULES"
}

disappend() {
  [ -f "$CLOAKING_RULES" ] || return 1
  tmp="${CLOAKING_RULES}.tmp"
  sed '/^# custom hosts$/,$d' "$CLOAKING_RULES" > "$tmp"
  mv "$tmp" "$CLOAKING_RULES"
}

case "$1" in
  append)    append   ;;
  disappend) disappend ;;
  *)         exit 1   ;;
esac
