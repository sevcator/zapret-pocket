#!/bin/bash

autohostlist="--hostlist-auto=$MODPATH/autohostlist.txt --hostlist-exclude=$MODPATH/exclude.txt"
autohostlist2="--hostlist=$MODPATH/autohostlist.txt --hostlist-exclude=$MODPATH/exclude.txt"
youtubehostlist="--hostlist=$MODPATH/youtube.txt"

# Here you can configure the zapret
# If you don't know what you're doing, don't touch anything
# New value in config must add $config

# Auto Host List
config="--filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig $autohostlist --new"
config="$config --filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig $autohostlist --new"
config="$config --filter-udp=80 --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/quic.bin $autohostlist2 --new"
config="$config --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/quic.bin $autohostlist2 --new"

# YouTube
config="$config --filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODPATH/tls.bin $youtubehostlist --new"
config="$config --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/quic.bin $youtubehostlist --new"

# Discord
config="$config --filter-udp=50000-50099 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n4 --ipset=$MODPATH/ipset-discord.txt"
