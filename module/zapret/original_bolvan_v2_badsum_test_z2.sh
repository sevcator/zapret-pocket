# Zapret Configuration
# >.<

# original_bolvan_v2_badsum_test_z2.sh
# source-profile: original_bolvan_v2_badsum_test
# Translated from zapret1 (nfqws) to zapret2 (nfqws2) syntax.
ZAPRET=2

config="--blob=ovlpat_tls_clienthello_11:@$MODPATH/zapret/tls_clienthello_11.bin --blob=fake_quic_initial_www_google_com:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_3:@$MODPATH/zapret/quic_3.bin --blob=fake_tls_clienthello_www_google_com:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=multidisorder:seqovl=1:pos=1,host+2,sld+2,sld+5,sniext+1,sniext+2,endhost-2 --lua-desync=multisplit:seqovl=286:seqovl_pattern=ovlpat_tls_clienthello_11 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=multisplit:seqovl=1:pos=midsld+1 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=fake_quic_initial_www_google_com:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --out-range=-n3 --lua-desync=fake:blob=fake_quic_3:repeats=2 --lua-desync=udplen:increment=4 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=http_req --lua-desync=fake:blob=0x0F0F0F0F:tcp_md5 --lua-desync=multisplit:seqovl=2:pos=host+1 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=tls_client_hello --lua-desync=fake:blob=fake_tls_clienthello_www_google_com:repeats=6:tcp_md5:ip_autottl=-2,3-20 --lua-desync=multisplit --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=all --out-range=-n3 --lua-desync=fake:blob=0x00000000000000000000000000000000 --new"
fi
