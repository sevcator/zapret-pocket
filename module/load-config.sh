#!/bin/bash

hostlist="--hostlist-exclude=$MODPATH/exclude.txt --hostlist-auto=$MODPATH/autohostlist.txt"

# Here you can configure the zapret
# If you don't know what you're doing, don't touch anything
config="--filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODPATH/tls.bin $hostlist --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/main-services.txt --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODPATH/tls.bin --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/main-services.txt --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODPATH/tls.bin --new"
config="$config --filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig --dpi-desync-fake-tls=$MODPATH/tls.bin $hostlist --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/main-services.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/quic.bin --new"
config="$config --filter-udp=80 --hostlist=$MODPATH/main-services.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/quic.bin --new"
config="$config --filter-udp=80 --dpi-desync=fake --dpi-desync-repeats=11 $hostlist --new"
config="$config --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 $hostlist --new"
config="$config --filter-udp=50000-50099 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n4"
