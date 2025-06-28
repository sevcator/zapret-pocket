boot_wait() {
    while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done
}
boot_wait
MODPATH="/data/adb/modules/zapret"
su -c "$MODPATH/zapret-main.sh"