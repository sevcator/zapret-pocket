MODPATH=/data/adb/modules/zapret

while true; do
    mode=$(cat "$MODPATH/config/dnscrypt-files-mode")

    if [ "$mode" = "1" ] || [ "$mode" = "2" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL -o "$MODPATH/dnscrypt/cloaking-rules.txt" "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/main/cloaking-rules.txt"
        elif command -v wget > /dev/null 2>&1; then
            wget -q -O "$MODPATH/dnscrypt/cloaking-rules.txt" "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/main/cloaking-rules.txt"
        fi
    fi

    if [ "$mode" = "2" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL -o "$MODPATH/dnscrypt/blocked-names.txt" "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/main/blocked-names.txt"
        elif command -v wget > /dev/null 2>&1; then
            wget -q -O "$MODPATH/dnscrypt/blocked-names.txt" "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/main/blocked-names.txt"
        fi
    fi

    if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
        . "$MODPATH/dnscrypt/make-unkillable.sh" &
        "$MODPATH/dnscrypt/dnscrypt-proxy" > /dev/null
    fi

    sleep 5
done