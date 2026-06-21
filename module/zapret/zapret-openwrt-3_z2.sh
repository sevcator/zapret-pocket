# Zapret Configuration
# >.<

# zapret-openwrt-3_z2.sh (nfqws2 / ZAPRET=2 translation of zapret-openwrt-3.sh)
# source-discussion: remittor/zapret-openwrt#168
# Author: remittor
# Strategy: Intersvyaz Chelyabinsk - fakedsplit+ttl=4+padencap
# Translated from --dpi-desync* to --lua-desync= per _zapret2_mapping.md (CORRECTED FULL SPEC).
ZAPRET=2

config="--blob=fake_tls_google:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fakedsplit:pos=1,midsld:blob=fake_tls_google:ip_ttl=4:repeats=16:tls_mod=padencap --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=fakeddisorder:blob=fake_default_tls:ip_ttl=4:repeats=16:tls_mod=padencap --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_google:repeats=16 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=16 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fakedsplit:blob=0x00000000000000000000000000000000:ip_ttl=4:repeats=16 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=fakedsplit:blob=0x00000000000000000000000000000000:ip_ttl=4:repeats=16 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=discord_ip_discovery,stun --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --new"
fi
