MODPATH=/data/adb/modules/zapret

call_error() {
    "$MODPATH/log-error.sh" "Curl/wget not found on system"
}

while true; do
    if command -v curl > /dev/null 2>&1; then
        curl -o "$MODPATH/dnscrypt/blocked-names.txt" "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/blocked-names.txt"
        curl -o "$MODPATH/dnscrypt/cloaking-rules.txt" "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/cloaking-rules.txt"
    elif command -v wget > /dev/null 2>&1; then
        wget -O "$MODPATH/dnscrypt/blocked-names.txt" "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/blocked-names.txt"
        wget -O "$MODPATH/dnscrypt/cloaking-rules.txt" "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/cloaking-rules.txt"
    else
        call_error
    fi
    
    if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
        . "$MODPATH/dnscrypt/make-unkillable-dnscrypt.sh" &
        "$MODPATH/dnscrypt/dnscrypt-proxy" > /dev/null
    fi

    sleep 5
done
