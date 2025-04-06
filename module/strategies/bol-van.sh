#!/bin/bash

# Zapret Configuration
config="--filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist-exclude=$MODPATH/list-exclude.txt --hostlist-auto=$MODPATH/list-auto.txt --new"
config="$config --filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist=$MODPATH/list.txt --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list.txt --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=$MODPATH/tls_clienthello_www_google_com.bin --new"
config="$config --filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig --hostlist-exclude=$MODPATH/list-exclude.txt --hostlist-auto=$MODPATH/list-auto.txt --new"
config="$config --filter-udp=80,443 --hostlist=$MODPATH/list.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/quic_initial_www_google_com.bin --new"
config="$config --filter-udp=80,443 --dpi-desync=fake --dpi-desync-repeats=11 --hostlist-exclude=$MODPATH/list-exclude.txt --hostlist-auto=$MODPATH/list-auto.txt --new"
config="$config --filter-udp=50000-50099 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol --dpi-desync-cutoff=n4 --new"
config="$config --filter-tcp=80,443 --ipset=$MODPATH/ipset-host.txt --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new"
config="$config --filter-udp=80,443 --ipset=$MODPATH/ipset-host.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/quic_initial_www_google_com.bin"