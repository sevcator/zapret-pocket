# Zapret Configuration
# >.<

# YTDisBystro_34_Amazon3_z2.sh
# source-profile: YTDisBystro_34_Amazon3
# Translated to zapret2 (nfqws2 / --lua-desync) from YTDisBystro_34_Amazon3.sh
ZAPRET=2

config="--blob=syn_data_4:@$MODPATH/zapret/tls_clienthello_4.bin --blob=syn_data_7:@$MODPATH/zapret/tls_clienthello_7.bin --blob=fake_tls_9:@$MODPATH/zapret/tls_clienthello_9.bin --blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_4:@$MODPATH/zapret/quic_4.bin --blob=fake_http_MS:@$MODPATH/zapret/http_fake_MS.bin --blob=ovlpat_5:@$MODPATH/zapret/tls_clienthello_5.bin --blob=fake_udp_6:@$MODPATH/zapret/quic_6.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --lua-desync=syndata:blob=syn_data_4:ip_autottl=-1,3-20 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=tls_client_hello --lua-desync=syndata:blob=syn_data_7:ip_autottl=-1,3-20 --lua-desync=fake:blob=fake_tls_9:tls_mod=rnd,dupsid:tcp_md5:ip_autottl=-1,3-20 --lua-desync=multisplit:pos=sld+1 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --out-range=-n3 --lua-desync=fake:blob=fake_quic_4:repeats=2 --lua-desync=udplen:increment=4 --out-range=a --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=http_req --lua-desync=fake:blob=fake_http_MS:tcp_md5 --lua-desync=multisplit:pos=sld+1:seqovl=2 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=tls_client_hello --lua-desync=multisplit:seqovl=211:seqovl_pattern=ovlpat_5 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --out-range=-n4 --lua-desync=fake:blob=fake_udp_6:payload=all:repeats=2:ip_ttl=7 --out-range=a --new"
fi
