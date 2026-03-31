# Zapret Configuration
# >.<

config=" --filter-udp=443 --hostlist=$MODPATH/lists/list-general.txt --hostlist=$MODPATH/lists/list-general-user.txt --hostlist-exclude=$MODPATH/lists/list-exclude.txt --hostlist-exclude=$MODPATH/lists/list-exclude-user.txt --ipset-exclude=$MODPATH/lists/ipset-exclude.txt --ipset-exclude=$MODPATH/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/fake/quic_initial_www_google_com.bin --new"
config="$config --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6 --new"
config="$config --filter-l3=ipv4 --filter-tcp=80,443,2053,2083,2087,2096,8443 --ipset-exclude=$MODPATH/lists/ipset-exclude.txt --ipset-exclude=$MODPATH/lists/ipset-exclude-user.txt --dpi-desync=syndata,multidisorder --new"
config="$config --filter-udp=443 --ipset=$MODPATH/lists/ipset-all.txt --hostlist-exclude=$MODPATH/lists/list-exclude.txt --hostlist-exclude=$MODPATH/lists/list-exclude-user.txt --ipset-exclude=$MODPATH/lists/ipset-exclude.txt --ipset-exclude=$MODPATH/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/fake/quic_initial_www_google_com.bin"
