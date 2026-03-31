#!/system/bin/sh

MODPATH="/data/adb/modules/zapret"
CURRENTSTRATEGY=$(cat "$MODPATH/current-strategy" 2>/dev/null)
CURRENTIPSET=$(cat "$MODPATH/current-ipset" 2>/dev/null)
STRATEGYDIR="$MODPATH/strategy"

if [ -d "$MODPATH/strategies" ] && [ ! -d "$STRATEGYDIR" ]; then
    STRATEGYDIR="$MODPATH/strategies"
fi

if [ -z "$CURRENTSTRATEGY" ]; then
    CURRENTSTRATEGY="(not set)"
fi
if [ -z "$CURRENTIPSET" ]; then
    CURRENTIPSET="(not set)"
fi

start_service() {
    if pgrep -f nfqws > /dev/null; then
        echo "! nfqws is already started"
    else
        nohup "$MODPATH/service.sh" > /dev/null 2>&1 &
        echo "- Service started"
    fi
}

stop_service() {
    iptables -t mangle -F PREROUTING
    iptables -t mangle -F POSTROUTING
    for pid in $(pgrep -f zapret.sh); do
        kill -9 $pid
    done
    pkill nfqws
    pkill dnscrypt-proxy
    echo "- Service stopped"
}

toggle_service() {
    if pgrep -f nfqws > /dev/null; then
        stop_service
    else
        start_service
    fi
}

restart_service() {
    stop_service
    sleep 1
    start_service
}

select_strategy() {
    echo "- Available strategies:"
    for strategy in "$STRATEGYDIR"/*.sh; do
        [ -f "$strategy" ] || continue
        echo "$(basename "$strategy" .sh)"
    done
    echo "- Enter the strategy:"
    read user_strategy
    if [ -f "$STRATEGYDIR/$user_strategy.sh" ]; then
        echo "$user_strategy" > "$MODPATH/current-strategy"
        echo "- Done!"
        echo "- Run 'zapret restart' to use this config now"
    else
        echo "! Invalid name of strategy"
    fi
}

select_ipset() {
    echo "- Available IPSet filters:"
    for ipset_filter in "$MODPATH"/ipset/*.txt; do
        [ -f "$ipset_filter" ] || continue
        echo "$(basename "$ipset_filter" .txt)"
    done
    echo "- Enter the IPSet filter:"
    read user_ipset
    if [ -f "$MODPATH/ipset/$user_ipset.txt" ]; then
        echo "$user_ipset" > "$MODPATH/current-ipset"
        echo "- Done!"
        echo "- Run 'zapret restart' if you want to re-read your setup now"
    else
        echo "! Invalid name of IPSet filter"
    fi
}

if [ "$1" = "start" ]; then
    start_service
elif [ "$1" = "stop" ]; then
    stop_service
elif [ "$1" = "toggle" ]; then
    toggle_service
elif [ "$1" = "restart" ]; then
    restart_service
elif [ "$1" = "strategy" ]; then
    select_strategy
elif [ "$1" = "ipset" ]; then
    select_ipset
else
    echo "zapret @ github.com/sevcator/zapret-magisk <3"
    echo ""
    echo "- Current strategy: $CURRENTSTRATEGY"
    echo "- Current IPSet filter: $CURRENTIPSET"
    echo ""
    echo "- Available commands:"
    echo "zapret start - Start the zapret service"
    echo "zapret stop - Stop the zapret service"
    echo "zapret restart - Restart the zapret service"
    echo "zapret toggle - Start/stop the zapret service"
    echo "zapret strategy - Pick a strategy for DPI modification"
    echo "zapret ipset - Pick an IPSet filter"
fi;
