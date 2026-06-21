# Zapret Configuration
# >.<

# ankddev10_z2.sh
# source-profile: ankddev10 (zapret2 / nfqws2 translation)
# Translated from ankddev10.sh per _zapret2_mapping.md (CORRECTED FULL SPEC).
ZAPRET=2

config="--blob=fake_tls_vk_kyber:@$MODPATH/zapret/tls_clienthello_vk_com_kyber.bin --blob=fake_tls_google:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_google_general:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=ovlpat_tls7:@$MODPATH/zapret/tls_clienthello_7.bin --blob=fake_tls_google_calls:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=syndata:blob=fake_tls_vk_kyber:payload=all:tcp_md5:repeats=10 --lua-desync=multidisorder:pos=4 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=syndata:blob=fake_tls_google:payload=all:tcp_seq=-10000:repeats=11 --lua-desync=multidisorder:pos=3 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_google:payload=all:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_google_general:payload=all:repeats=11 --lua-desync=udplen:increment=15 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=multisplit:pos=2,midsld-2:seqovl=1:seqovl_pattern=ovlpat_tls7 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=fake:blob=fake_tls_google_calls:payload=all:tcp_md5:ip_autottl=-2,3-20:repeats=6 --lua-desync=multisplit:pos=2 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=all --out-range=-d5 --lua-desync=fake:blob=0x00000000000000000000000000000000:payload=all:repeats=11 --new"
fi
