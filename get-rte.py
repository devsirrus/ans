#!/usr/bin/env python3
import os, sys, re
import ipaddress
import radix

# decide host
host = "ans01"
dstip = "10.0.0.1"
dstip = "192.168.0.1"

# Linux routing table info
def get_linux_nexthop(host, ip):
    # ip/mask regex
    Is_startip = re.compile('^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])')
    path = "./file/" + host + ".txt"
    try:
        f = open(path, "r")
    except FileNotFoundError:
        print("file not found:" + path)
        sys.exit(1)

    rtree = radix.Radix()
    gateway_dict = dict()
    for line in f:
        # Check only lines starting with IP address
        if Is_startip.match(line):
            i = line.split()
            dest = i[0]
            mask = i[2]
            gw = i[1]

            prefix_addr = str(ipaddress.IPv4Network(dest + "/" + mask))
            gateway_dict[prefix_addr] = gw
            rnode = rtree.add(prefix_addr)
    else:
        use_route = rtree.search_best(ip)
        use_gw =  gateway_dict[str(use_route.prefix)]
        if use_gw == "0.0.0.0" :
            use_gw = "directly connected"

    f.close()
    return(use_gw)

dstip = "100.0.0.1"

nexthop = get_linux_nexthop("ans01" , dstip)
print(nexthop)

#    print("destip:" + dstip + " Dstnet:" + str(use_route.prefix) + " nexthop:" + str(use_nexthop))



