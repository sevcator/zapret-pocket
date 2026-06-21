# Zapret Configuration
# >.<

# zapret-openwrt-4_z2.sh (nfqws2 / ZAPRET=2 translation of zapret-openwrt-4.sh)
# source-discussion: remittor/zapret-openwrt#168
# Author: remittor
# Strategy: YouTube ALT MGTS - fake+udplen-increment=10+udplen-pattern=0xDEADBEEF
# Generated from learn.html using only --dpi-desync* parameters and zapret-pocket-main lists.
ZAPRET=2

config="--blob=fake_quic_www_google_com:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_tls_www_google_com:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_www_google_com:payload=all:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --out-range=-d3 --lua-desync=fake:blob=0x00000000000000000000000000000000:payload=all:repeats=6 --new"
config="$config --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_tls_www_google_com:payload=all:ip_autottl=-2,3-20:tcp_seq=-10000:repeats=6 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=fake:blob=fake_tls_www_google_com:payload=all:ip_autottl=-2,3-20:tcp_seq=-10000:repeats=6 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=0x00000000000000000000000000000000:payload=all:ip_autottl=-2,3-20:tcp_md5 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=fake:blob=fake_tls_www_google_com:payload=all:ip_autottl=-2,3-20:tcp_seq=-10000:repeats=6 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=all --out-range=-d3 --lua-desync=fake:blob=0x00000000000000000000000000000000:payload=all:repeats=6 --new"
fi
