#!/bin/bash
# Flowseal ALT6 Configuration from https://github.com/Flowseal/zapret-discord-youtube
# Added option Fake TLS Mode
# Hosting providers configuration from YTDisBystro

# Zapret Configuration
# <-- -->

config="--filter-tcp=80 --hostlist=$MODPATH/list/custom.txt --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/providers.txt --hostlist=$MODPATH/list/reestr.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset=$MODPATH/ipset/ipset-v4.txt --ipset=$MODPATH/ipset/ipset-v6.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake,multisplit --dpi-desync-fooling=md5sig --dpi-desync-split-pos=midsld --dpi-desync-fake-http=0x00000000 --dpi-desync-autottl --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/custom.txt --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/providers.txt --hostlist=$MODPATH/list/reestr.txt --hostlist-exclude=$MODPATH/list/exclude.txt --dpi-desync=multisplit --dpi-desync-repeats=2 --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new"
config="$config --filter-udp=80,443 --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/reestr.txt --hostlist=$MODPATH/list/custom.txt --hostlist=$MODPATH/list/providers.txt --ipset=$MODPATH/ipset/custom.txt --hostlist-exclude=$MODPATH/list/exclude.txt --hostlist-exclude=$MODPATH/list/default.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/fake/quic_initial_www_google_com.bin.bin --new"

config="$config --filter-l3=ipv4 --filter-tcp=443 --ipset=$MODPATH/ipset/custom.txt --ipset=$MODPATH/ipset/ipset-v4.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=multisplit --dpi-desync-split-seqovl=226 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_18.bin --dup=2 --dup-cutoff=n3 --new"
config="$config --filter-l3=ipv6 --filter-tcp=443 --ipset=$MODPATH/ipset/ipset-v6.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=multisplit --dpi-desync-split-seqovl=226 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_18.bin --dup=2 --dup-cutoff=n3 --new"
config="$config --filter-udp=80,443 --ipset=$MODPATH/ipset/custom.txt --ipset=$MODPATH/ipset/ipset-v4.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=$MODPATH/fake/quic_for_tls_clienthello_18.bin --dpi-desync-cutoff=n2 --new"

# Discord RTC
config="$config --filter-udp=50000-50100 --filter-l7=discord --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-cutoff=n2"
