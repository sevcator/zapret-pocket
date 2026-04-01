#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
. "$MODPATH/common.sh"

ensure_layout
stop_module_service
echo "- Service stopped"
