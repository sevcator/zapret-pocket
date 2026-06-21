# Zapret Configuration
# >.<

# fake-i_z2.sh (nfqws2 / lua-desync translation of fake-i.sh)
# source-discussion: remittor/zapret-openwrt#168
# Author: fake-i
# Strategy: split2 ipset + multisplit hostlist + multidisorder QUIC
# Generated from information.ms using only --dpi-desync* parameters and zapret-pocket-main lists.
ZAPRET=2

config="--blob=g_tls:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --blob=g_quic:@$MODPATH/zapret/quic_initial_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=multisplit:seqovl=681:seqovl_pattern=g_tls --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=fake:blob=g_tls:tls_mod=rnd,dupsid,sni=fonts.google.com:tcp_seq=-10000 --lua-desync=multisplit:pos=2 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=g_quic:repeats=8 --lua-desync=multidisorder:pos=2 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=g_quic:repeats=8 --lua-desync=multidisorder:pos=2 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_default_http:tcp_md5:ip_autottl=-1,3-20 --lua-desync=multisplit:pos=2 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=multisplit:pos=2:seqovl=652:seqovl_pattern=g_tls --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --new"
fi
