#!/bin/bash
# Strategy by sevcator

# Zapret Configuration
# <-- -->

# Default list
config="--filter-tcp=80 --hostlist=$MODPATH/list/default.txt --dpi-desync=fakedsplit --dpi-desync-fooling=md5sig --dpi-desync-split-pos=method+2 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/default.txt --dpi-desync=multisplit --dpi-desync-split-seqovl=226 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_18.bin --dup=2 --dup-cutoff=n3 --new"
config="$config --filter-udp=80,443 --hostlist=$MODPATH/list/default.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/fake/quic_for_tls_clienthello_18.bin --new"

# Other banned sites/resources
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/reestr.txt --hostlist=$MODPATH/list/custom.txt --ipset=$MODPATH/ipset/custom.txt --hostlist-exclude=$MODPATH/list/default.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fakedsplit --dpi-desync-fooling=md5sig --dpi-desync-split-pos=method+2 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/reestr.txt --hostlist=$MODPATH/list/custom.txt --ipset=$MODPATH/ipset/custom.txt --hostlist-exclude=$MODPATH/list/default.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=multisplit --dpi-desync-split-seqovl=226 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_18.bin --dup=2 --dup-cutoff=n3 --new"
config="$config --filter-udp=80,443 --hostlist=$MODPATH/list/reestr.txt --hostlist=$MODPATH/list/custom.txt --ipset=$MODPATH/ipset/custom.txt --hostlist-exclude=$MODPATH/list/default.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/fake/quic_for_tls_clienthello_18.bin --new"

# Cloudflare, Amazon and etc.
config="$config --filter-tcp=80 --ipset=$MODPATH/ipset/ipset-all.txt --hostlist=$MODPATH/list/providers.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=443 --ipset=$MODPATH/ipset/ipset-all.txt --hostlist=$MODPATH/list/providers.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --new"
config="$config --filter-udp=80,443 --ipset=$MODPATH/ipset/ipset-all.txt --hostlist=$MODPATH/list/providers.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=$MODPATH/fake/quic_initial_www_google_com.bin --dpi-desync-cutoff=n2 --new"

# Discord RTC
config="$config --filter-udp=50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-autottl --dup=2 --dup-autottl --dup-cutoff=n3"