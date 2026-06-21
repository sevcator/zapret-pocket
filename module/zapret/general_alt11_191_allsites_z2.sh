# Zapret Configuration
# >.<

# general_alt11_191_allsites_z2.sh
# source-profile: general_alt11_191_allsites
# Translated from zapret1 (nfqws) to zapret2 (nfqws2) syntax per _zapret2_mapping.md.
# This is the zapret2 variant.
ZAPRET=2

config="--blob=syn_data_tls_clienthello_4:@$MODPATH/zapret/tls_clienthello_4.bin --blob=fake_quic_initial_www_google_com:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_3:@$MODPATH/zapret/quic_3.bin --blob=ovlpat_tls_clienthello_7:@$MODPATH/zapret/tls_clienthello_7.bin --blob=fake_tls_clienthello_max_ru:@$MODPATH/zapret/tls_clienthello_max_ru.bin --blob=fake_discord_stun_q:@$MODPATH/zapret/quic_initial_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=syndata:blob=syn_data_tls_clienthello_4:ip_autottl=-1,3-20 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=multisplit:pos=midsld+1:seqovl=1 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_initial_www_google_com:repeats=11 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --out-range=-n3 --lua-desync=fake:blob=fake_quic_3:repeats=2 --lua-desync=udplen:increment=4 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=multisplit:pos=2,midsld-2:seqovl=1:seqovl_pattern=ovlpat_tls_clienthello_7 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=fake:blob=fake_tls_clienthello_max_ru:tcp_ts=-1000:tcp_ts_up:repeats=8 --lua-desync=multisplit:pos=1:seqovl=654:seqovl_pattern=fake_tls_clienthello_max_ru --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=discord_ip_discovery,stun --lua-desync=fake:blob=fake_discord_stun_q:repeats=6 --new"
fi
