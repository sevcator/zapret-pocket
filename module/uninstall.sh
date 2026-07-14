#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

ensure_layout
stop_module_service
# stop_module_service only tears down the zapret/dnscrypt stack. The Telegram
# bypass proxy is a separate long-lived process, so stop it explicitly here —
# otherwise removing the module leaves an orphaned Python proxy running until reboot.
stop_tg_ws_proxy
echo "- Service stopped"
