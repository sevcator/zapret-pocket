# Zapret Configuration
# >.<

# alt10_190b_z2.sh
# source-profile: alt10_190b
# zapret2 (nfqws2) translation of alt10_190b.sh, generated from --dpi-desync* parameters.
ZAPRET=2

config="--blob=syndata_tls4:@$MODPATH/zapret/tls_clienthello_4.bin --blob=fake_tls_google:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_tls_4pda:@$MODPATH/zapret/tls_clienthello_4pda_to.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --lua-desync=syndata:blob=syndata_tls4:ip_autottl=-1,3-20 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_tls_google:repeats=6:tcp_ts=-1000:tcp_ts_up --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=quic_initial --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_tls_4pda:repeats=6:tcp_ts=-1000:tcp_ts_up --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=tls_client_hello --lua-desync=fake:blob=fake_tls_4pda:repeats=6:tcp_ts=-1000:tcp_ts_up --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --new"
fi
