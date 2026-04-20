# Zapret Configuration
# >.<

# general_alt11_191_allsites.sh
# source-profile: general_alt11_191_allsites
# Generated from zapret-pocket-main strategies using only --dpi-desync* parameters.

config="--filter-tcp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --dpi-desync=syndata --dpi-desync-fake-syndata=$MODPATH/zapret/tls_clienthello_4.bin --dpi-desync-autottl --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list-google.txt --dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld+1 --new"
config="$config --filter-udp=443 --ipset=$MODPATH/list/ipset-all.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$MODPATH/zapret/quic_initial_www_google_com.bin --new"
config="$config --filter-udp=443 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --dpi-desync=fake,udplen --dpi-desync-udplen-increment=4 --dpi-desync-fake-quic=$MODPATH/zapret/quic_3.bin --dpi-desync-cutoff=n3 --dpi-desync-repeats=2 --new"
config="$config --filter-tcp=80 --hostlist=$MODPATH/list/list-general.txt --hostlist=$MODPATH/list/list-general-user.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --hostlist-exclude=$MODPATH/list/list-exclude-user.txt --ipset-exclude=$MODPATH/list/ipset-exclude.txt --ipset-exclude=$MODPATH/list/ipset-exclude-user.txt --dpi-desync=multisplit --dpi-desync-split-pos=2,midsld-2 --dpi-desync-split-seqovl=1 --dpi-desync-split-seqovl-pattern=$MODPATH/zapret/tls_clienthello_7.bin --new"
if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then
    config="$config --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=654 --dpi-desync-split-pos=1 --dpi-desync-fooling=ts --dpi-desync-repeats=8 --dpi-desync-split-seqovl-pattern=$MODPATH/zapret/tls_clienthello_max_ru.bin --dpi-desync-fake-tls=$MODPATH/zapret/tls_clienthello_max_ru.bin --new"
    config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-fake-discord=$MODPATH/zapret/quic_initial_www_google_com.bin --dpi-desync-fake-stun=$MODPATH/zapret/quic_initial_www_google_com.bin --dpi-desync-repeats=6 --new"
fi
