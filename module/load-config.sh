#!/bin/bash

hostlist="--hostlist-exclude=$MODPATH/list-exclude.txt --hostlist-auto=$MODPATH/list.txt"

# Here you can configure the zapret
# If you don't know what you're doing, don't touch anything
config="--filter-tcp=80 $hostlist --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODPATH/tls.bin --new"
config="$config --filter-tcp=443 $hostlist --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODPATH/tls.bin --new"
config="$config --filter-udp=50000-50100 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=8 --new"
config="$config --filter-udp=80 $hostlist --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/quic.bin --new"
config="$config --filter-udp=443 $hostlist --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/quic.bin --new"
