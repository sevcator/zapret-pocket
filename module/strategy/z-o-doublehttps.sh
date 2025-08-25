#!/bin/bash
# Strategy from discussions zapret-openwrt (https://github.com/remittor/zapret-openwrt/discussions/168?sort=new#discussioncomment-13482197)

# Zapret Configuration
# <-- -->

config="--filter-tcp=80 --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/reestr.txt --hostlist=$MODPATH/list/custom.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset=$MODPATH/ipset/custom.txt --ipset=$MODPATH/ipset/ipset-v4.txt --ipset=$MODPATH/ipset/ipset-v6.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake,fakedsplit --dpi-desync-fooling=md5sig,badseq --dpi-desync-autottl --new"

config="$config --filter-tcp=443 --hostlist=$MODPATH/list/custom.txt --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/reestr.txt --hostlist-exclude=$MODPATH/list/exclude.txt --dpi-desync=split2 --dpi-desync-split-seqovl=681 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/custom.txt --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/reestr.txt --hostlist-exclude=$MODPATH/list/exclude.txt --dpi-desync=fake,multisplit --dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com --dpi-desync-fooling=badseq --dpi-desync-fake-tls=$MODPATH/fake/tls_clienthello_www_google_com.bin --new"

config="$config --filter-udp=80,443 --hostlist=$MODPATH/list/default.txt --hostlist=$MODPATH/list/reestr.txt --hostlist=$MODPATH/list/custom.txt --hostlist-exclude=$MODPATH/list/exclude.txt --ipset=$MODPATH/ipset/custom.txt --ipset=$MODPATH/ipset/ipset-v4.txt --ipset=$MODPATH/ipset/ipset-v6.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/fake/quic_initial_www_google_com.bin --new"

config="$config --filter-tcp=443 --ipset=$MODPATH/ipset/custom.txt --ipset=$MODPATH/ipset/ipset-v4.txt --ipset=$MODPATH/ipset/ipset-v6.txt --ipset-exclude=$MODPATH/ipset/exclude.txt --dpi-desync=split2 --dpi-desync-repeats=2 --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq,hopbyhop2 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --dup=2 --dup-cutoff=n3 --new"

if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
   config="$config --filter-udp=50000-65535 --filter-l7=discord --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-cutoff=n2 --new"
   config="$config --filter-l3=ipv4 --filter-udp=1400,50000-65535 --filter-l7=stun,unknown --dpi-desync=fake --dpi-desync-autottl --dup=2 --dup-autottl --dup-cutoff=n3 --new"
   config="$config --filter-l3=ipv6 --filter-udp=1400,50000-65535 --filter-l7=stun,unknown --dpi-desync=fake --dpi-desync-autottl6 --dup=2 --dup-autottl6 --dup-cutoff=n3"
fi
