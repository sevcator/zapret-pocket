# Zapret Configuration
# >.<

# YTDisBystro_31_3_z2.sh
# source-profile: YTDisBystro_31_3 (zapret2 / nfqws2 translation)
# Translated from YTDisBystro_31_3.sh per _zapret2_mapping.md "CORRECTED FULL SPEC".

ZAPRET=2

config="--blob=syn_data_1:@$MODPATH/zapret/tls_clienthello_7.bin --blob=syn_data_2:@$MODPATH/zapret/tls_clienthello_7.bin --blob=fake_tls_9:@$MODPATH/zapret/tls_clienthello_9.bin --blob=fake_quic_wgoogle:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_4:@$MODPATH/zapret/quic_4.bin --blob=fake_tls_wgoogle:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=syndata:blob=syn_data_1 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=syndata:blob=syn_data_2 --lua-desync=fake:blob=fake_tls_9:tls_mod=rnd,dupsid:tcp_md5:ip_autottl=-1,3-20 --lua-desync=multisplit:pos=sld+1 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_wgoogle:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --out-range=-n3 --lua-desync=fake:blob=fake_quic_4:repeats=2 --lua-desync=udplen:increment=4 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=0x0F0F0F0F:tcp_md5 --lua-desync=multisplit:pos=sld+1:seqovl=2 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=fake:blob=fake_tls_wgoogle:repeats=6:tcp_md5:ip_autottl=-2,3-20 --lua-desync=multisplit:pos=2 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=discord_ip_discovery,stun --lua-desync=fake:blob=0x00000000000000000000000000000000:ip_autottl=-1,3-20 --new"
fi
