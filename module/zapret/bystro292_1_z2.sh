# Zapret Configuration
# >.<

# bystro292_1_z2.sh
# source-profile: bystro292_1 (translated nfqws1 -> nfqws2)
# Generated from zapret-pocket-main strategies using only --dpi-desync* parameters.

ZAPRET=2

config="--blob=syn_data_tls4:@$MODPATH/zapret/tls_clienthello_4.bin --blob=ovlpat_tls7:@$MODPATH/zapret/tls_clienthello_7.bin --blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_4:@$MODPATH/zapret/quic_4.bin --blob=fakedpat_tls1:@$MODPATH/zapret/tls_clienthello_1.bin --blob=fake_tls_google:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --lua-desync=syndata:blob=syn_data_tls4:tcp_seq=-10000 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=tls_client_hello --lua-desync=multisplit:pos=midsld+1:seqovl=1:seqovl_pattern=ovlpat_tls7 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --out-range=-n3 --lua-desync=fake:blob=fake_quic_4:repeats=2 --lua-desync=udplen:increment=4 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=http_req --lua-desync=fakeddisorder:pos=2,midsld:pattern=fakedpat_tls1:tcp_seq=-10000 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=tls_client_hello --lua-desync=fake:blob=fake_tls_google:repeats=6:tcp_md5:ip_autottl=-2,3-20 --lua-desync=multisplit:pos=2 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=discord_ip_discovery,stun --lua-desync=fake:blob=0x00000000000000000000000000000000 --new"
fi
