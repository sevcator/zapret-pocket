# Zapret Configuration
# >.<

# buddymurdock_z2.sh
# source-discussion: remittor/zapret-openwrt#168
# Author: buddymurdock
# Strategy: MTS Krasnodar ttl=4 padencap
# Generated from information.ms using only --dpi-desync* parameters and zapret-pocket-main lists.
# zapret2 (nfqws2) translation of buddymurdock.sh
ZAPRET=2

config="--blob=fake_quic_www_google_com:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=ovlpat_tls_www_google_com:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_www_google_com:repeats=11 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=fake:blob=0x00000000000000000000000000000000 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=16 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fakeddisorder:ip_ttl=4:repeats=16:tls_mod=padencap --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fakedsplit:ip_ttl=4:repeats=16 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=multisplit:pos=2:seqovl=652:seqovl_pattern=ovlpat_tls_www_google_com --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --lua-desync=fake:blob=0x00000000000000000000000000000000 --new"
fi
