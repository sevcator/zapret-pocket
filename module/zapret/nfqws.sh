MODPATH="/data/adb/modules/zapret"
while true; do
    if ! pgrep -x "nfqws" > /dev/null; then
	    "$MODPATH/zapret/nfqws" --uid=0:0 --bind-fix4 --bind-fix6 --qnum=200 $config
    fi
    sleep 5
done