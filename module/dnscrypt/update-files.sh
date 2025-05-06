#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"

if [ "$(cat "$MODPATH/config/dnscrypt-cloaking-update" 2>/dev/null)" = "1" ]; then
    LINK_TO_CLOAKING=$(cat "$MODPATH/config/cloaking-rules-link" 2>/dev/null)
    if [ -n "$LINK_TO_CLOAKING" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL -o "$MODPATH/dnscrypt/cloaking-rules.txt" "$LINK_TO_CLOAKING"
        else
            echo "curl not found, can't download cloaking file" >> "$MODPATH/warns.log"
        fi
    else
        echo "Cloaking rules link not found" >> "$MODPATH/warns.log"
    fi
fi

if [ "$(cat "$MODPATH/config/dnscrypt-blocking-update" 2>/dev/null)" = "1" ]; then
    LINK_TO_BLOCKED=$(cat "$MODPATH/config/blocked-names-link" 2>/dev/null)
    if [ -n "$LINK_TO_BLOCKED" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL -o "$MODPATH/dnscrypt/blocked-names.txt" "$LINK_TO_BLOCKED"
        else
            echo "curl not found, can't download blocked-names file" >> "$MODPATH/warns.log"
        fi
    else
        echo "Blocked names link not found" >> "$MODPATH/warns.log"
    fi
fi
