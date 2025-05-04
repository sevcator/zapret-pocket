MODPATH="/data/adb/modules/zapret"
CURRENTSTRATEGY=$(cat "$MODPATH/config/current-strategy" 2>/dev/null || echo "Unknown")
DNSCRYPTENABLE=$(cat "$MODPATH/config/dnscrypt-enable" 2>/dev/null || echo "Unknown")
CLOAKINGUPDATE=$(cat "$MODPATH/config/dnscrypt-cloaking-update" 2>/dev/null || echo "Unknown")
CLOAKINGRULESLINK=$(cat "$MODPATH/config/cloaking-rules-link" 2>/dev/null || echo "Unknown")

echo "! Zapret Module for Magisk; @sevcator/zapret-magisk"
echo ""

case "$DNSCRYPTENABLE" in
    1) echo "- DNSCrypt-Proxy enabled" ;;
    0) echo "- No DNS" ;;
    *) echo "- Unknown DNS state" ;;
esac

case "$CLOAKINGUPDATE" in
    1) echo "- Auto-update hosts enabled" ;;
    0) echo "- Auto-update hosts disabled" ;;
    *) echo "- Unknown auto-update hosts state" ;;
esac

if [ -f "$CLOAKINGRULESLINK" ]; then
    echo "- Current link: $CLOAKINGRULESLINK"
else
    echo "- Unknown hosts link state"
fi

if [ -f "$CURRENTSTRATEGY" ]; then
    echo "- Current strategy: $CURRENTSTRATEGY"
else
    echo "- Unknown strategy state"
fi

echo ""

su -c "$MODPATH/system/bin/zapret toggle"
