#!/bin/bash
# zapret-discord-youtube by Flowseal (https://github.com/Flowseal/zapret-discord-youtube)

# Values
hostlist="--hostlist=$MODPATH/list.txt"

# Zapret Configuration
config="--filter-udp=443 $hostlist --dpi-desync=fake --dpi-desync-repeats=8 --dpi-desync-fake-quic=$MODPATH/quic-google.bin --new"
config="$config --filter-udp=50000-50100 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d4 --dpi-desync-repeats=8 --new"
config="$config --filter-tcp=80 $hostlist --dpi-desync=fake,split2 --dpi-desync-autottl=3 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=443 $hostlist --dpi-desync=fake --dpi-desync-ttl=4 --dpi-desync-fake-tls-mod=rnd,rndsni,padencap"
