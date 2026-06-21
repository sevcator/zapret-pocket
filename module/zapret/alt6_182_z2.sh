# Zapret Configuration
# >.<

# alt6_182_z2.sh
# source-profile: alt6_182 (translated to zapret2 / nfqws2)
# Generated from zapret-pocket-main strategies, translated from --dpi-desync* to --lua-desync.
ZAPRET=2

config="--blob=syn_data:@$MODPATH/zapret/tls_clienthello_4.bin --blob=tls_clienthello_www_google_com:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --blob=quic_initial_www_google_com:@$MODPATH/zapret/quic_initial_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=syndata:blob=syn_data:ip_autottl=-1,3-20 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=tls_client_hello --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=tls_clienthello_www_google_com:ip6_hopbyhop:ip6_hopbyhop2 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=quic_initial_www_google_com:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=quic_initial_www_google_com:repeats=6 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=http_req --lua-desync=fake:blob=fake_default_http:tcp_md5:ip_autottl=-2,3-20 --lua-desync=multisplit:pos=2 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=tls_client_hello --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=tls_clienthello_www_google_com:ip6_hopbyhop:ip6_hopbyhop2 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --new"
fi
