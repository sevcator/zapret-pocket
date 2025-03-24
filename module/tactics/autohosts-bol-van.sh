#!/bin/bash
# Default zapret configuration (https://github.com/bol-van/zapret-win-bundle)

# Values
autohostlist="--hostlist-exclude=$MODPATH/list-exclude.txt --hostlist-auto=$MODPATH/list-auto.txt"
hostlist="--hostlist=$MODPATH/list.txt"

# Zapret Configuration
config="--filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig $autohostlist --new"
config="$config --filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig $hostlist --new"
config="$config --filter-tcp=443 $hostlist --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODPATH/tls-google.bin --new"
config="$config --filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig $autohostlist --new"
config="$config --filter-udp=443 $hostlist --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/quic-google.bin --new"
config="$config --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 $autohostlist --new"
config="$config --filter-udp=50000-50099 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n4"
