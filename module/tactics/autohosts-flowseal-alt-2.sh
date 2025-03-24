#!/bin/bash
# zapret-discord-youtube by Flowseal (https://github.com/Flowseal/zapret-discord-youtube)

# Values
autohostlist="--hostlist-exclude=$MODPATH/list-exclude.txt --hostlist-auto=$MODPATH/list-auto.txt"
hostlist="--hostlist=$MODPATH/list.txt"

# Zapret Configuration
config="--filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig $autohostlist --new"
config="$config --filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig $hostlist --new"
config="$config --filter-udp=443 $hostlist --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/quic-google.bin --new"
config="$config --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 $autohostlist --new"
config="$config --filter-udp=50000-50100 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new"
config="$config --filter-tcp=443 $hostlist --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=$MODPATH/tls.bin --new"
config="$config --filter-tcp=443 --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=$MODPATH/tls.bin $autohostlist --new"
