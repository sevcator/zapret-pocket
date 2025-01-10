#!/bin/bash
# t.me/sevcator 0_o Tuno Diagnostic Tyl dlya zapreta XD

if pgrep -x "nfqws" > /dev/null; then
    echo "- nfqws is running"
    exit
else
    echo "- nfqws is not running"
fi

if pgrep -f "$MODDIR/zapret.sh" > /dev/null || pgrep -f "$MODDIR/service.sh" > /dev/null; then
    echo "- Service script is runnning"
else
    echo "- Service script is not runnning"

    echo "- Starting service"
    $MODDIR/service.sh &

    if [ $? -eq 0 ]; then
        echo "- The service started"
    else
        echo "! Failed to run start service"
    fi
fi
