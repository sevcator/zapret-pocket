#!/bin/bash

# Zapret Configuration
config="--filter-udp=80,443 --hostlist=$MODPATH/list.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/quic_initial_www_google_com.bin --new"
config="$config --filter-udp=50000-50100 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list.txt --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list.txt --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=$MODPATH/tls_clienthello_www_google_com.bin --new"
config="$config --filter-udp=80,443 --ipset=$MODPATH/ipset-host.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/quic_initial_www_google_com.bin --new"
config="$config --filter-udp=80,443 --hostlist-auto=$MODPATH/list-auto.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/quic_initial_www_google_com.bin --new"
config="$config --filter-tcp=80 --ipset=$MODPATH/ipset-host.txt --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=80 --hostlist-auto=$MODPATH/list-auto.txt --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=443 --ipset=$MODPATH/ipset-host.txt --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=$MODPATH/tls_clienthello_www_google_com.bin --new"
config="$config --filter-tcp=443 --hostlist-auto=$MODPATH/list-auto.txt --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=$MODPATH/tls_clienthello_www_google_com.bin --new"