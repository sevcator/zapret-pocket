# Zapret Configuration
# >.<

# original_bolvan_v2_badsum_2_z2.sh
# source-profile: original_bolvan_v2_badsum_2
# Translated from zapret1 (nfqws) to zapret2 (nfqws2) per _zapret2_mapping.md (CORRECTED FULL SPEC).

ZAPRET=2

config="--blob=syn_data_tls_clienthello_4:@$MODPATH/zapret/tls_clienthello_4.bin --blob=fake_quic_initial_www_google_com:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_3:@$MODPATH/zapret/quic_3.bin --blob=fake_unknown_udp_quic_6:@$MODPATH/zapret/quic_6.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=syndata:blob=syn_data_tls_clienthello_4:ip_autottl=-1,3-20 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=fake:blob=fake_default_tls:repeats=6:tcp_seq=-10000:tls_mod=rnd,dupsid,sni=www.google.com --lua-desync=multidisorder:pos=1,midsld --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_initial_www_google_com:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --out-range=-n3 --lua-desync=fake:blob=fake_quic_3:repeats=2 --lua-desync=udplen:increment=4 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=0x0F0F0F0F:tcp_md5 --lua-desync=multisplit:seqovl=2:pos=1,midsld --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=fake:blob=fake_default_tls:repeats=6:tcp_seq=-10000 --lua-desync=multidisorder:pos=1,midsld --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=all --out-range=-n4 --lua-desync=fake:blob=fake_unknown_udp_quic_6:payload=all:repeats=2:ip_ttl=7 --new"
fi
