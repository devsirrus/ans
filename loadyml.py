#!/usr/bin/env python3
import yaml
with open('config.yml', 'r') as f:
    config = yaml.load(f)

# {'127.0.0.1': [{'hostname': 'myhost1'}, {'interface': 'eth1'}, {'vrf': 'none'}], '127.0.0.20': [{'hostname': 'myhost20'}, {'interface': 'eth1'}, {'vrf': 'VRF-20'}], '127.0.0.2': [{'hostname': 'myhost2'}, {'interface': 'eth1'}, {'vrf': 'VRF-1'}]}
# print(config)

ip = "127.0.0.2"
#key = [ k for k, v in config.items() if k == ip]

for i in config[ip]:
#    key = [ k for k, v in i.items()]
    if "hostname" in i.keys():
        hostname = i['hostname']
    if "interface" in i.keys():
        interface = i['interface']
    if "vrf" in i.keys():
        vrf = i['vrf']

# print(hostname)
# print(interface)
# print(vrf)

# with open('output.yaml', 'w') as file:
#     yaml.dump(config[ip], file)
with open('output.yaml', 'w') as file:
    yaml.dump(config, file)
