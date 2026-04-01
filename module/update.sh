#!/system/bin/sh

MODPATH=/data/adb/modules/zapret

mkdir -p \
    "$MODPATH/config" \
    "$MODPATH/list" \
    "$MODPATH/ipset" \
    "$MODPATH/dnscrypt" \
    "$MODPATH/strategy" \
    "$MODPATH/fake" \
    "$MODPATH/bin"

if [ -d "$MODPATH/strategies" ] && [ ! -d "$MODPATH/strategy" ]; then
    mv "$MODPATH/strategies" "$MODPATH/strategy"
fi

for FILE in \
    "$MODPATH/list/custom.txt" \
    "$MODPATH/list/exclude.txt" \
    "$MODPATH/ipset/custom.txt" \
    "$MODPATH/ipset/exclude.txt" \
    "$MODPATH/config/debug" \
    "$MODPATH/dnscrypt/dnscrypt-proxy-arm" \
    "$MODPATH/dnscrypt/dnscrypt-proxy-arm64" \
    "$MODPATH/dnscrypt/dnscrypt-proxy-i386" \
    "$MODPATH/dnscrypt/dnscrypt-proxy-x86_64" \
    "$MODPATH/dnscrypt/cloaking-rules.txt" \
    "$MODPATH/dnscrypt/custom-cloaking-rules.txt" \
    "$MODPATH/dnscrypt/blocked-names.txt" \
    "$MODPATH/dnscrypt/blocked-ips.txt" \
    "$MODPATH/dnscrypt/custom-blocked-names.txt" \
    "$MODPATH/dnscrypt/custom-blocked-ips.txt" \
    "$MODPATH/dnscrypt/custom-allowed-names.txt" \
    "$MODPATH/dnscrypt/custom-allowed-ips.txt"; do
    case "$FILE" in
        "$MODPATH/config/debug")
            [ -e "$FILE" ] || printf '1\n' > "$FILE"
            ;;
        *)
            [ -e "$FILE" ] || : > "$FILE"
            ;;
    esac
done
