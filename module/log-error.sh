MODPATH=/data/adb/modules/zapret
DATE=$(date '+%Y-%m-%d %H:%M:%S')

if [ $# -eq 0 ]; then
    echo "Usage: $0 <error_message>"
    exit 1
fi

echo "[$DATE] $1" >> "$MODPATH/error.log"
