#!/bin/bash
# YTDisBystro by KDS (https://ntc.party/t/ytdisbystro/12582), ported by sevcator

# Values
autohostlist="--hostlist-exclude=$MODPATH/list-exclude.txt --hostlist-auto=$MODPATH/list-auto.txt"
hostlist="--hostlist=$MODPATH/list.txt"

# Zapret Configuration
config="--filter-tcp=80 --dpi-desync=fake,split2 --dpi-desync-fooling=md5sig $autohostlist --new"
config="$config --filter-tcp=80 --dpi-desync=fake,split2 --dpi-desync-fooling=md5sig $hostlist --new"
config="$config --filter-tcp=80 --dpi-desync=fake,split2 --dpi-desync-fooling=md5sig --hostlist-domains=googlevideo.com --new"
config="$config --filter-tcp=80 --dpi-desync=fake,split2 --dpi-desync-fooling=md5sig --hostlist-domains=youtube.com,googlevideo.com,gvt1.com,play.google.com,ytimg.com,ggpht.com,jnn-pa.googleapis.com --new"
config="$config --filter-tcp=443 $hostlist --dpi-desync=fake,split2 --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=3 --dpi-desync-fake-tls=$MODPATH/tls-google.bin --dpi-desync-ttl=3 --new"
config="$config --filter-tcp=443 --hostlist-domains=googlevideo.com --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-ttl=4 --new"
config="$config --filter-tcp=443 --dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls=$MODPATH/tls-google.bin $autohostlist --dpi-desync-ttl=5 --new"
config="$config --filter-udp=443 --hostlist-domains=youtube.com,googlevideo.com,gvt1.com,play.google.com,ytimg.com,ggpht.com,jnn-pa.googleapis.com --dpi-desync=fake --dpi-desync-repeats=4 --dpi-desync-fake-quic=$MODPATH/quic-google.bin --new"
config="$config --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 $autohostlist --new"
config="$config --filter-udp=50000-50099 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=n1 --dpi-desync-fake-quic=$MODPATH/quic-google.bin"
