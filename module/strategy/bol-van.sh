#!/bin/bash

# Zapret Configuration
# <-- -->

# list.txt
config="--filter-tcp=80 --hostlist=$MODPATH/list/list.txt --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list.txt --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new"
config="$config --filter-udp=80,443 --hostlist=$MODPATH/list/list.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/fake/quic_initial_www_google_com.bin --new"

# list-auto.txt
config="$config --filter-tcp=80 --hostlist-auto=$MODPATH/list/list-auto.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --dpi-desync=fake,split2 --dpi-desync-fooling=md5sig --dpi-desync-autottl --new"
config="$config --filter-tcp=443 --hostlist-auto=$MODPATH/list/list-auto.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --dpi-desync=fake,split2 --dpi-desync-fooling=md5sig --dpi-desync-split-seqovl=3 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls=$MODPATH/fake/tls_clienthello_www_google_com.bin --dpi-desync-autottl --new"
config="$config --filter-udp=80,443 --hostlist-auto=$MODPATH/list/list-auto.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --dpi-desync=fake --dpi-desync-repeats=11 --new"

# ipset-host.txt
config="$config --filter-tcp=80 --ipset=$MODPATH/ipset/ipset-host.txt --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=443 --ipset=$MODPATH/ipset/ipset-host.txt --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig --new"
config="$config --filter-udp=80,443 --ipset=$MODPATH/ipset/ipset-host.txt --dpi-desync=fake --dpi-desync-repeats=11 --new"

# ipset-discord.txt
config="$config --filter-udp=50000-50100 --filter-l7=discord,stun --dpi-desync=fake"