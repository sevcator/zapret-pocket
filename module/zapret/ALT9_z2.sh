# Zapret Configuration (zapret2 variant)
# >.<
ZAPRET=2

config="--blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --new"
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=hostfakesplit:host=www.google.com:repeats=4:tcp_ts=-1000:tcp_ts_up --new"
fi
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=hostfakesplit:host=www.google.com:repeats=4:tcp_ts=-1000:tcp_ts_up:ip_id=zero --new"
config="$config --filter-tcp=80,443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=hostfakesplit:host=ozon.ru:repeats=4:tcp_ts=-1000:tcp_ts_up:tcp_md5 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
config="$config --filter-tcp=80,443,8443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=hostfakesplit:host=ozon.ru:repeats=4:tcp_ts=-1000:tcp_ts_up --new"
