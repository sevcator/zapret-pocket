# Zapret Configuration
# >.<

# warp1_z2.sh
# source-profile: warp1 (zapret2 / nfqws2 translation of warp1.sh)
# Generated from zapret-pocket-main strategies; --dpi-desync* translated to --lua-desync=.
ZAPRET=2

config="--blob=fake_tls_clienthello_5:@$MODPATH/zapret/tls_clienthello_5.bin --blob=fake_tls_clienthello_7:@$MODPATH/zapret/tls_clienthello_7.bin --blob=fake_quic_initial_www_google_com:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_3:@$MODPATH/zapret/quic_3.bin --blob=fake_tls_clienthello_www_google_com:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_tls_clienthello_5:tls_mod=rnd:tcp_md5:tcp_seq=-10000:ip_autottl=-1,3-20 --lua-desync=multidisorder:pos=midsld+1:seqovl=1 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_tls_clienthello_7:tls_mod=rnd,padencap:tcp_md5:tcp_seq=-10000:ip_autottl=-1,3-20 --lua-desync=multisplit:seqovl=1 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=fake_quic_initial_www_google_com:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --out-range=-n3 --lua-desync=fake:blob=fake_quic_3:repeats=2 --lua-desync=udplen:increment=4 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=http_req --lua-desync=fake:blob=fake_default_http:tcp_md5:ip_autottl=-1,3-20 --lua-desync=multisplit:pos=sld+1 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=tls_client_hello --lua-desync=fake:blob=fake_tls_clienthello_www_google_com:repeats=6:tcp_md5:ip_autottl=-2,3-20 --lua-desync=multisplit --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --out-range=-n3 --lua-desync=fake:blob=0x00000000000000000000000000000000:payload=all --new"
fi
