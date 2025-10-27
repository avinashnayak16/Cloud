# Quick Deploy: Private 5G Network

This is a streamlined deployment package for setting up a private 5G network using Open5GS and UERANSIM.

## Directory Structure

```
deploy/
├── vm1-open5gs/         # Files for VM1 (192.168.159.129)
│   ├── setup.sh        # Main setup script
│   └── config/         # Configuration files
│       ├── amf.yaml
│       └── upf.yaml
└── vm2-ueransim/       # Files for VM2 (192.168.159.130)
    ├── setup.sh        # UERANSIM setup script
    └── config/         # Configuration files
        ├── gnb.yaml
        └── ue.yaml
```

## Quick Start

### On VM1 (Open5GS Core - 192.168.159.129):

1. Copy the `vm1-open5gs` folder to the VM
2. Run:
```bash
cd vm1-open5gs
chmod +x setup.sh
./setup.sh
```

3. Copy config files:
```bash
sudo cp config/amf.yaml /etc/open5gs/
sudo cp config/upf.yaml /etc/open5gs/
sudo systemctl restart open5gs-amfd open5gs-upfd
```

### On VM2 (UERANSIM - 192.168.159.130):

1. Copy the `vm2-ueransim` folder to the VM
2. Run:
```bash
cd vm2-ueransim
chmod +x setup.sh
./setup.sh
```

3. Copy config files:
```bash
cp config/gnb.yaml UERANSIM/config/
cp config/ue.yaml UERANSIM/config/
```

4. Start gNB:
```bash
cd UERANSIM
./build/nr-gnb -c config/gnb.yaml
```

5. In another terminal, start UE:
```bash
cd UERANSIM
sudo ./build/nr-ue -c config/ue.yaml
```

## WebUI Access

- URL: http://localhost:9999
- Username: admin
- Password: 1423

## Default Test Subscriber

- IMSI: 901700000000001
- Key: 465B5CE8B199B49FAA5F0A2EE238A6BC
- OPC: E8ED289DEBA952E4283B54E88E6183CA

## Testing Connection

After setup, test the connection:
```bash
ping -I uesimtun0 google.com
```

## Troubleshooting

View logs:
```bash
# On VM1
sudo tail -f /var/log/open5gs/amf.log
sudo tail -f /var/log/open5gs/upf.log
sudo journalctl -u mongod

# On VM2
# Check gNB and UE terminal outputs
```