# Zapret Configuration
# >.<

# discordtcp80_z2.sh
# source-profile: discordtcp80 (zapret2 / nfqws2 translation)
# Generated from zapret-pocket-main strategies; --dpi-desync* -> --lua-desync per _zapret2_mapping.md.
ZAPRET=2

config="--blob=fake_tls_3:@$MODPATH/zapret/tls_clienthello_3.bin --blob=fake_quic_google:@$MODPATH/zapret/quic_initial_www_google_com.bin --blob=fake_quic_test00:@$MODPATH/zapret/quic_test_00.bin --blob=fake_tls_google:@$MODPATH/zapret/tls_clienthello_www_google_com.bin --filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_tls_3:ip_ttl=2 --lua-desync=multisplit:pos=sniext+1:seqovl=1 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --payload=all --out-range=-d2 --lua-desync=multisplit:pos=1 --out-range=a --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=fake_quic_google:repeats=6 --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --out-range=-n2 --lua-desync=fake:blob=fake_quic_test00:repeats=2 --out-range=a --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --payload=all --lua-desync=fake:blob=0x00000000000000000000000000000000:tcp_md5:ip_autottl=-2,3-20 --lua-desync=multisplit:pos=2 --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --payload=all --lua-desync=fake:blob=fake_tls_google:tcp_md5:ip_autottl=-2,3-20:repeats=6 --lua-desync=multisplit:pos=2 --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=all --out-range=-d3 --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --out-range=a --new"
fi
