#!/bin/bash
# Custom strategy by sevcator

# Zapret Configuration
# <-- -->

# Default list
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/default.txt --dpi-desync=fake,multisplit --dpi-desync-split-pos=sld+1 --dpi-desync-fooling=md5sig --dpi-desync-autottl --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/default.txt --dpi-desync=fake,split2 --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new"
config="$config --filter-udp=80,443 --hostlist=$MODPATH/list/default.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/fake/quic_initial_www_google_com.bin --new"

# Reestr Roscomnadzor (github.com/bol-van/rulist)
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/reestr_hostname.txt --hostlist-exclude=$MODPATH/list/default.txt --dpi-desync=fake,multisplit --dpi-desync-split-pos=sld+1 --dpi-desync-fooling=md5sig --dpi-desync-autottl --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/reestr_hostname.txt --hostlist-exclude=$MODPATH/list/default.txt --dpi-desync=fake,split2 --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new"
config="$config --filter-udp=80,443 --hostlist=$MODPATH/list/reestr_hostname.txt --hostlist-exclude=$MODPATH/list/default.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/fake/quic_initial_www_google_com.bin --new"

# IPset of banned hosting providers
config="$config --filter-tcp=80 --ipset=$MODPATH/ipset/ipset-all.txt --hostlist=$MODPATH/list/providers.txt --dpi-desync=fake,multisplit --dpi-desync-split-pos=sld+1 --dpi-desync-fooling=md5sig --dpi-desync-autottl --new"
config="$config --filter-tcp=443 --ipset=$MODPATH/ipset/ipset-all.txt --hostlist=$MODPATH/list/providers.txt --dpi-desync=fake,split2 --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new"
config="$config --filter-udp=80,443 --ipset=$MODPATH/ipset/ipset-all.txt --hostlist=$MODPATH/list/providers.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/fake/quic_initial_www_google_com.bin --new"

# Discord RTC
config="$config --filter-l7=discord --filter-udp=50000-50100 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-cutoff=n2"