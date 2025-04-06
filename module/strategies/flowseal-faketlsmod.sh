#!/bin/bash

# Zapret Configuration
config="--filter-udp=80,443 --hostlist=$MODPATH/list.txt --dpi-desync=fake --dpi-desync-repeats=8 --dpi-desync-fake-quic=$MODPATH/quic_initial_www_google_com.bin --new"
config="$config --filter-udp=50000-50100 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d4 --dpi-desync-repeats=8 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list.txt --dpi-desync=fake,split2 --dpi-desync-autottl=3 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list.txt --dpi-desync=fake --dpi-desync-ttl=4 --dpi-desync-fake-tls-mod=rnd,rndsni,padencap --new"
config="$config --filter-udp=80,443 --ipset=$MODPATH/ipset-host.txt --dpi-desync=fake --dpi-desync-repeats=8 --dpi-desync-fake-quic=$MODPATH/quic_initial_www_google_com.bin --new"
config="$config --filter-udp=80,443 --hostlist-auto=$MODPATH/list-auto.txt --dpi-desync=fake --dpi-desync-repeats=8 --dpi-desync-fake-quic=$MODPATH/quic_initial_www_google_com.bin --new"
config="$config --filter-tcp=80 --ipset=$MODPATH/ipset-host.txt --dpi-desync=fake,split2 --dpi-desync-autottl=3 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=80 --hostlist-auto=$MODPATH/list-auto.txt --dpi-desync=fake,split2 --dpi-desync-autottl=3 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=443 --ipset=$MODPATH/ipset-host.txt --dpi-desync=fake --dpi-desync-ttl=4 --dpi-desync-fake-tls-mod=rnd,rndsni,padencap --new"
config="$config --filter-tcp=443 --hostlist-auto=$MODPATH/list-auto.txt --dpi-desync=fake --dpi-desync-ttl=4 --dpi-desync-fake-tls-mod=rnd,rndsni,padencap --new"