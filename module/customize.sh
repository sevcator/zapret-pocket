#!/system/bin/sh

if [[ -f "$MODDIR/sevcator.sh" ]]; then
    . $MODDIR/sevcator.sh
fi
if [[ -f "$MODUPDATEDIR/sevcator.sh" ]]; then
    . $MODUPDATEDIR/sevcator.sh
fi

abort
