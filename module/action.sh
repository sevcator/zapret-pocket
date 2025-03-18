#!/system/bin/bash
MODPATH=/data/adb/modules/zapret

echo "**********************************"
echo "*             zapret             *"
echo "**********************************"
echo ! The button 'Aciton' is only toggling zapret!
echo ! If you need the config zapret, open Terminal, type su and type zapret
echo 
su -c "$MODPATH/system/bin/zapret toggle"
