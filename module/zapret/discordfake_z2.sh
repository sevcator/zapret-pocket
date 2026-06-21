# Zapret Configuration
# >.<

# discordfake_z2.sh
# source-profile: discordfake (zapret2 / nfqws2 translation)
# Translated from discordfake.sh using --lua-desync / --payload / --blob per _zapret2_mapping.md
ZAPRET=2

config="--blob=fake_tls3:@$MODPATH/zapret/tls_clienthello_3.bin --blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_test00:@$MODPATH/zapret/quic_test_00.bin --blob=ovlpat_tls7:@$MODPATH/zapret/tls_clienthello_7.bin --blob=fake_tls_google:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_tls3:ip_ttl=2 --lua-desync=multisplit:pos=sniext+1:seqovl=1 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=tls_client_hello --out-range=-d2 --lua-desync=multisplit:pos=1 --out-range=a --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --out-range=-n2 --lua-desync=fake:blob=fake_quic_test00:repeats=2 --out-range=a --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=http_req --lua-desync=multisplit:pos=2,midsld-2:seqovl=1:seqovl_pattern=ovlpat_tls7 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=tls_client_hello --lua-desync=fake:blob=fake_tls_google:tcp_md5:ip_autottl=-2,3-20:repeats=6 --lua-desync=multisplit:pos=2 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=discord_ip_discovery,stun --out-range=-d2 --lua-desync=fake:blob=fake_quic_test00:payload=all --lua-desync=multisplit:pos=2 --out-range=a --new"
fi
