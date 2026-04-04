#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

# Wait for boot to complete before doing anything
while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 2
done

# Ensure directories and default config exist (was update.sh)
ensure_layout
ensure_default_config

for file in "$LIST_DIR/list-general-user.txt" \
            "$LIST_DIR/list-exclude-user.txt" \
            "$IPSET_DIR/ipset-exclude.txt" \
            "$IPSET_DIR/ipset-exclude-user.txt" \
            "$DNSCRYPT_DIR/cloaking-rules.txt" \
            "$DNSCRYPT_DIR/blocked-names.txt" \
            "$DNSCRYPT_DIR/blocked-ips.txt"; do
    [ -e "$file" ] || : > "$file"
done

# Update lists from user-configured URLs before starting services
refresh_linked_lists

# Start services
if [ -f "$MODPATH/system/bin/zapret" ]; then
    sh "$MODPATH/system/bin/zapret" start >/dev/null 2>&1
fi
