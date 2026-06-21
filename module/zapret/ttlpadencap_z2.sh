# Zapret Configuration
# >.<

# ttlpadencap_z2.sh
# source-profile: ttlpadencap (translated to zapret2 / nfqws2)
# Generated from zapret-pocket-main strategies using --lua-desync* parameters.
ZAPRET=2

config="--blob=syn_data:@$MODPATH/zapret/tls_clienthello_4.bin --blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_google2:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=ovlpat:@$MODPATH/zapret/tls_clienthello_7.bin --blob=fake_tls_google:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --blob=fake_quic_discord:@$MODPATH/zapret/quic_initial_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=syndata:blob=syn_data:ip_autottl=-1,3-20 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=fake:blob=fake_default_tls:tcp_md5:ip_autottl=-1,3-20 --lua-desync=multisplit:pos=2 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_google2:repeats=6 --lua-desync=udplen:increment=10:pattern=0xDEADBEEF --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=multisplit:pos=2,midsld-2:seqovl=1:seqovl_pattern=ovlpat --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=fake:blob=fake_tls_google:repeats=6:tcp_md5:ip_autottl=-2,3-20 --lua-desync=multisplit:pos=2 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=all --out-range=-d3 --lua-desync=fake:blob=fake_quic_discord:payload=all:repeats=6 --out-range=a --new"
fi
