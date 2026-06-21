# Zapret Configuration
# >.<

# zapret-openwrt-5_z2.sh (nfqws2 / ZAPRET=2 translation of zapret-openwrt-5.sh)
# source-discussion: remittor/zapret-openwrt#168
# Author: remittor
# Strategy: v72 old - fake,fakeddisorder with split-pos=10,midsld + sni=fonts.google.com + vk_com.bin + gosuslugi_ru.bin
# Generated from learn.html using only --dpi-desync* parameters and zapret-pocket-main lists.
ZAPRET=2

config="--blob=fakedpat_vk:@$MODPATH/zapret/tls_clienthello_vk_com.bin --blob=ovlpat_gosuslugi:@$MODPATH/zapret/tls_clienthello_gosuslugi_ru.bin --blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=ovlpat_discord:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=0x0F0F0F0F:tcp_seq=0:badsum --lua-desync=fakeddisorder:pos=10,midsld:pattern=fakedpat_vk:seqovl=336:seqovl_pattern=ovlpat_gosuslugi:tcp_seq=0:badsum --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --lua-desync=multisplit:pos=1,sniext+1:seqovl=1 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_default_quic:repeats=6 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_default_http:ip_autottl=-2,3-20:badsum --lua-desync=fakedsplit:pos=2:ip_autottl=-2,3-20:badsum --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=multisplit:pos=2:seqovl=652:seqovl_pattern=ovlpat_discord --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=stun,discord_ip_discovery --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --new"
fi
