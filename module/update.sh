#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

ensure_layout
ensure_default_config

mkdir -p "$IPSET_DIR"

for file in "$LIST_DIR/list-general-user.txt" "$LIST_DIR/list-exclude-user.txt" "$IPSET_DIR/ipset-exclude.txt" "$IPSET_DIR/ipset-exclude-user.txt" "$DNSCRYPT_DIR/cloaking-rules.txt" "$DNSCRYPT_DIR/blocked-names.txt" "$DNSCRYPT_DIR/blocked-ips.txt"; do
    [ -e "$file" ] || : > "$file"
done
