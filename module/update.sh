#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

ensure_layout
ensure_default_config

mkdir -p "$MODPATH/ipset"

for file in \
    "$LIST_DIR/custom.txt" \
    "$LIST_DIR/exclude.txt" \
    "$MODPATH/ipset/custom.txt" \
    "$MODPATH/ipset/exclude.txt" \
    "$DNSCRYPT_DIR/cloaking-rules.txt" \
    "$DNSCRYPT_DIR/blocked-names.txt" \
    "$DNSCRYPT_DIR/blocked-ips.txt" \
    "$DNSCRYPT_DIR/custom-cloaking-rules.txt" \
    "$DNSCRYPT_DIR/custom-blocked-names.txt" \
    "$DNSCRYPT_DIR/custom-blocked-ips.txt" \
    "$DNSCRYPT_DIR/custom-allowed-names.txt" \
    "$DNSCRYPT_DIR/custom-allowed-ips.txt"; do
    [ -e "$file" ] || : > "$file"
done
