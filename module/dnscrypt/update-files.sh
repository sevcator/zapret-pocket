#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
CLOAKINGUPDATE=$(cat "$MODPATH/config/dnscrypt-cloaking-update" 2>/dev/null || echo "0")
CLOAKINGRULESLINK=$(cat "$MODPATH/config/cloaking-rules-link" 2>/dev/null || echo "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/cloaking-rules.txt")
BLOCKEDUPDATE=$(cat "$MODPATH/config/dnscrypt-blocked-update" 2>/dev/null || echo "0")
BLOCKEDNAMESLINK=$(cat "$MODPATH/config/blocked-names-link" 2>/dev/null || echo "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/blocked-names.txt")

if [ "$CLOAKINGUPDATE" = "1" ]; then
    if [ -n "$CLOAKINGRULESLINK" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL -o "$MODPATH/dnscrypt/cloaking-rules.txt" "$CLOAKINGRULESLINK"
        else
            echo "curl not found, can't download cloaking file" >> "$MODPATH/warns.log"
        fi
    else
        echo "Cloaking rules link not found" >> "$MODPATH/warns.log"
    fi
fi

if [ "$BLOCKEDUPDATE" = "1" ]; then
    if [ -n "$BLOCKEDNAMESLINK" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL -o "$MODPATH/dnscrypt/blocked-names.txt" "$BLOCKEDNAMESLINK"
        else
            echo "curl not found, can't download blocked-names file" >> "$MODPATH/warns.log"
        fi
    else
        echo "Blocked names link not found" >> "$MODPATH/warns.log"
    fi
fi
