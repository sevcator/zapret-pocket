# Zapret Configuration
# >.<
# zapret2 variant (auto-translated from ALT6.sh; nfqws1 --dpi-desync* -> nfqws2 --lua-desync=)
ZAPRET=2

config="--blob=fake_quic_g1:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=ovlpat_g3:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --blob=ovlpat_g4:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --blob=ovlpat_g5:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --blob=fake_quic_g6:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=ovlpat_g7:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_g1:payload=all:repeats=6 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --new"
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=ovlpat_g3 --new"
fi
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=ovlpat_g4:ip_id=zero --new"
config="$config --filter-tcp=80,443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=ovlpat_g5 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_g6:payload=all:repeats=6 --new"
config="$config --filter-tcp=80,443,8443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=multisplit:pos=1:seqovl=681:seqovl_pattern=ovlpat_g7 --new"
