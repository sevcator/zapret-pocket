# Zapret Configuration
# >.<

# MrFloppy62.sh
# source-discussion: remittor/zapret-openwrt#168
# Author: MrFloppy62
# Strategy: fake,multisplit + fooling=badseq + rnd,dupsid,sni=www.google.com + repeats=2+18
# Generated from learn.html using only --dpi-desync* parameters and zapret-pocket-main lists.
# Translated to zapret2 (nfqws2) per _zapret2_mapping.md "CORRECTED FULL SPEC".

ZAPRET=2

config="--blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=ovlpat_tls_google:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:repeats=2:tcp_md5:badsum --lua-desync=multisplit:pos=midsld --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=tls_client_hello --lua-desync=fake:blob=0x00000000:repeats=2:tcp_seq=-10000:tls_mod=rnd,dupsid,sni=www.google.com --lua-desync=multisplit:pos=midsld --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=fake_quic_google:repeats=18 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=fake_quic_google:repeats=18 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=http_req --lua-desync=fake:blob=fake_default_http:ip_autottl=-2,3-20:badsum --lua-desync=fakedsplit:pos=2:ip_autottl=-2,3-20:badsum --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=tls_client_hello --lua-desync=multisplit:pos=2:seqovl=652:seqovl_pattern=ovlpat_tls_google --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --new"
fi
