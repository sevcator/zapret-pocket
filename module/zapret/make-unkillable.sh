sleep 10
SCRIPT_PIDS=$(pgrep -f "zapret.sh")
NFQWS_PIDS=$(pgrep nfqws)
ALL_PIDS="$SCRIPT_PIDS $NFQWS_PIDS"
if [ -z "$ALL_PIDS" ]; then
    exit
fi
for pid in $ALL_PIDS; do
    if [ -d "/proc/$pid" ]; then
        echo -1000 > "/proc/$pid/oom_score_adj" 2>/dev/null
    fi
done
