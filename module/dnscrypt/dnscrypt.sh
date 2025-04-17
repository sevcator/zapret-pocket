MODPATH=/data/adb/modules/zapret

while true; do
    mode=$(cat "$MODPATH/config/dnscrypt-files-mode")

    if [ "$mode" = "1" ] || [ "$mode" = "2" ]; then
        CLOAKING_RULES_LINK=$(cat "$MODPATH/config/cloaking-rules-link")
        
        if [ -n "$CLOAKING_RULES_LINK" ]; then
            if command -v curl > /dev/null 2>&1; then
                curl -fsSL -o "$MODPATH/dnscrypt/cloaking-rules.txt" "$CLOAKING_RULES_LINK"
            elif command -v wget > /dev/null 2>&1; then
                wget -q -O "$MODPATH/dnscrypt/cloaking-rules.txt" "$CLOAKING_RULES_LINK"
            fi
        else
            echo "- Cloaking rules link is empty." > "$MODPATH/warns.log"
        fi
    fi

    if [ "$mode" = "2" ]; then
        BLOCKED_NAMES_LINK=$(cat "$MODPATH/config/blocked-names-link")
        
        if [ -n "$BLOCKED_NAMES_LINK" ]; then
            if command -v curl > /dev/null 2>&1; then
                curl -fsSL -o "$MODPATH/dnscrypt/blocked-names.txt" "$BLOCKED_NAMES_LINK"
            elif command -v wget > /dev/null 2>&1; then
                wget -q -O "$MODPATH/dnscrypt/blocked-names.txt" "$BLOCKED_NAMES_LINK"
            fi
        else
            echo "- Blocked names link is empty." > "$MODPATH/warns.log"
        fi
    fi

    if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
        . "$MODPATH/dnscrypt/make-unkillable.sh" &
        "$MODPATH/dnscrypt/dnscrypt-proxy" > /dev/null
    fi

    sleep 5
done
