sleep 10
SCRIPT_PIDS=$(pgrep -f "dnscrypt.sh")
DNSCRYPT_PIDS=$(pgrep dnscrypt-proxy)
ALL_PIDS="$SCRIPT_PIDS $DNSCRYPT_PIDS"
if [ -z "$ALL_PIDS" ]; then
    exit
fi
for pid in $ALL_PIDS; do
    if [ -d "/proc/$pid" ]; then
        echo -1000 > "/proc/$pid/oom_score_adj" 2>/dev/null
    fi
done
