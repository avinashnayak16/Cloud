#!/bin/bash
# Configuration files for Open5GS and UERANSIM

# AMF configuration
cat > amf.yaml << EOL
amf:
  sbi:
    server:
      - address: 192.168.159.129
        port: 7777
    client:
      scp:
        - uri: http://127.0.0.200:7777
  ngap:
    server:
      - address: 192.168.159.129
  metrics:
    server:
      - address: 192.168.159.129
EOL

# UPF configuration
cat > upf.yaml << EOL
upf:
  pfcp:
    - addr: 127.0.0.7
  gtpu:
    - addr: 192.168.159.130
EOL

# gNB configuration
cat > gnb.yaml << EOL
linkIp: 192.168.159.130
ngapIp: 192.168.159.130
gtpIp: 192.168.159.130
amfConfigs:
  - address: 192.168.159.129
    port: 38412
EOL

# UE configuration
cat > ue.yaml << EOL
supi: 'imsi-901700000000001'
mcc: '901'
mnc: '70'
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
op: 'E8ED289DEBA952E4283B54E88E6183CA'
opType: 'OPC'
amf: '8000'
imei: '356938035643803'
gnbSearchList:
  - 192.168.159.130
EOL