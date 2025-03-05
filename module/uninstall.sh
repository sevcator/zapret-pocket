#!/system/bin/sh

for pid in $(pgrep -f zapret.sh); do
    kill -9 $pid
done
su -c 'pkill nfqws'
su -c 'pkill zapret'
su -c 'iptables -t mangle -F PREROUTING'
su -c 'iptables -t mangle -F POSTROUTING'
