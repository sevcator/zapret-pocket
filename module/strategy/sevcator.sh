#!/bin/bash
# Strategy by sevcator
# <3

# Zapret Configuration
# <-- -->

config="--filter-tcp=80 --hostlist=$MODPATH/list/custom.txt --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/providers.txt --hostlist=$MODPATH/list/reestr.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset=$MODPATH/ipset/ipset-v4.txt --ipset=$MODPATH/ipset/ipset-v6.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http=$MODPATH/fake/http_fake_MS.bin --dpi-desync-fooling=md5sig --dup=2 --dup-fooling=md5sig --dup-cutoff=n3 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/custom.txt --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/providers.txt --hostlist=$MODPATH/list/reestr.txt --hostlist-exclude=$MODPATH/list/exclude.txt --dpi-desync=multisplit --dpi-desync-split-seqovl=226 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_18.bin --dup=2 --dup-cutoff=n3 --new"
config="$config --filter-udp=80,443 --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/reestr.txt --hostlist=$MODPATH/list/custom.txt --hostlist=$MODPATH/list/providers.txt --ipset=$MODPATH/ipset/custom.txt --hostlist-exclude=$MODPATH/list/exclude.txt --hostlist-exclude=$MODPATH/list/default.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/fake/quic_for_tls_clienthello_18.bin --new"

config="$config --filter-l3=ipv4 --filter-tcp=443 --ipset=$MODPATH/ipset/custom.txt --ipset=$MODPATH/ipset/ipset-v4.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=multisplit --dpi-desync-split-seqovl=226 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_18.bin --dup=2 --dup-cutoff=n3 --new"
config="$config --filter-l3=ipv6 --filter-tcp=443 --ipset=$MODPATH/ipset/ipset-v6.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=1,midsld --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls=$MODPATH/fake/tls_clienthello_9.bin --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new"
config="$config --filter-udp=80,443 --ipset=$MODPATH/ipset/custom.txt --ipset=$MODPATH/ipset/ipset-v4.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=$MODPATH/fake/quic_for_tls_clienthello_18.bin --dpi-desync-cutoff=n2 --new"

config="$config --filter-udp=50000-50100 --filter-l7=discord --dpi-desync=fake --dpi-desync-autottl --dup=2 --dup-autottl --dup-cutoff=n3"