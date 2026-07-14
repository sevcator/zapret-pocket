import sys, os
d = os.path.dirname(os.path.abspath(__file__))
parent = os.path.dirname(d)
pkg = os.path.join(parent, "tg-ws-proxy")
if os.path.basename(d) != "proxy":
    link = os.path.join(parent, "proxy")
    if not os.path.exists(link):
        os.symlink(d, link)
    sys.path.insert(0, parent)
else:
    sys.path.insert(0, parent)
from proxy.tg_ws_proxy import main
main()
