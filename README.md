# Private 5G Network Setup

A comprehensive guide to deploy a private 5G network using open-source software and hardware components.

## 🚀 Overview

This project provides step-by-step instructions to set up a complete private 5G network using:
- **5G Core**: Open5GS
- **RAN**: srsRAN Project
- **SDR Hardware**: USRP B210
- **Programmable SIM**: Open-Cells UICC tools
- **OS**: Ubuntu 22.04 LTS

## 📋 Prerequisites

### Hardware Requirements
- PC with Intel i7 processor and 32GB RAM
- Ubuntu 22.04 LTS installed
- USRP B210 software-defined radio (USB 3.0 connection)
- Programmable SIM card and USB card reader
- Stable internet connection

### Software Components
- Open5GS (5G Core Network)
- srsRAN Project (Radio Access Network)
- MongoDB (Database)
- Node.js (WebUI)
- UHD library (USRP drivers)

## 🛠️ Installation

### 1. MongoDB Setup

MongoDB serves as the database for Open5GS core network functions.

```bash
# Update system packages
sudo apt update
sudo apt install -y gnupg

# Add MongoDB repository
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

# Install and start MongoDB
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
sudo systemctl status mongod
```

### 2. Open5GS Installation

```bash
# Add Open5GS repository
sudo add-apt-repository ppa:open5gs/latest
sudo apt update

# Install Open5GS
sudo apt install -y open5gs

# Verify installation (should show 17 active services)
sudo systemctl status open5gs-*
sudo systemctl status open5gs-* | grep -c "active"
```

### 3. WebUI Setup

```bash
# Install Node.js
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs

# Install WebUI
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
```

**WebUI Access:**
- URL: http://localhost:9999
- Username: `admin`
- Password: `1423`

### 4. Network Configuration

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Configure NAT (replace eth0 with your interface)
sudo iptables -t nat -A POSTROUTING -o $(ip route show default | awk '/default/ {print $5}') -j MASQUERADE
sudo systemctl stop ufw
sudo iptables -I FORWARD 1 -j ACCEPT

# Persist iptables rules
sudo apt install -y iptables-persistent
sudo dpkg-reconfigure iptables-persistent
```

### 5. srsRAN Project Setup

```bash
# Install dependencies
sudo apt update
sudo apt install -y cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev libuhd-dev uhd-host

# Clone and build srsRAN
git clone https://github.com/srsRAN/srsRAN_Project.git
cd srsRAN_Project
mkdir build
cd build
cmake ../
make -j $(nproc)
make test -j $(nproc)
sudo make install
```

### 6. USRP B210 Setup

```bash
# Install UHD library and download firmware
sudo apt update
sudo apt install -y libuhd-dev uhd-host
sudo python3 /usr/lib/uhd/utils/uhd_images_downloader.py

# Verify USRP connection
uhd_find_devices
uhd_usrp_probe
```

## ⚙️ Configuration

### gNB Configuration

Edit the gNB configuration file:

```bash
cd srsRAN_Project/build/apps/gnb/
sudo nano gnb_rf_b200_tdd_n78_20mhz.yml
```

Key configuration parameters:

```yaml
cu_cp:
  amf:
    addr: 127.0.0.5
    port: 38412
    bind_addr: 127.0.0.5
    supported_tracking_areas:
      - tac: 7
        plmn_list:
          - plmn: "99970"

cell_cfg:
  dl_arfcn: 632628
  band: 78
  channel_bandwidth_MHz: 20
  common_scs: 30
  plmn: "99970"
  tac: 7
  pci: 1
```

### Programmable SIM Setup

```bash
# Extract and compile UICC tools
tar -xvzf uicc-v3.3.tgz
cd uicc-v3.3
make

# Program the SIM card
sudo ./program_uicc --adm 12345678 --imsi 999700000000001 --isdn 00000001 --acc 0001 --key 6874736969202073796d4b2079650a73 --opc 504f20634f6320504f50206363500a4f --spn "CSE" --authenticate --noreadafter
```

## 🚀 Running the Network

### 1. Start Core Network

```bash
# Restart Open5GS services
sudo systemctl restart open5gs-*
sudo systemctl status open5gs-* | grep -c "active"
```

### 2. Configure Subscriber

Access WebUI at http://localhost:9999 and add subscriber:
- **IMSI**: 999700000000001
- **Key**: 6874736969202073796d4b2079650a73
- **OPC**: 504f20634f6320504f50206363500a4f
- **DNN**: Enable IPv4 with dynamic IP allocation

### 3. Start gNB

```bash
cd srsRAN_Project/build/apps/gnb/
sudo ./gnb -c gnb_rf_b200_tdd_n78_20mhz.yml
```

## 🔧 Troubleshooting

### MongoDB Issues
```bash
# Check MongoDB logs
sudo journalctl -u mongod

# Restart MongoDB
sudo systemctl restart mongod
```

### Open5GS Services
```bash
# Check service status
sudo systemctl status open5gs-*

# View logs
sudo journalctl -u open5gs-amf
sudo tail -f /var/log/open5gs/amf.log
```

### USRP B210 Issues
```bash
# Verify USB 3.0 connection
lsusb | grep Ettus

# Reinstall UHD drivers
sudo apt install --reinstall libuhd-dev uhd-host
```

### gNB Connection Issues
- Verify IP addresses and ports in configuration files
- Check Open5GS AMF configuration: `/etc/open5gs/amf.yaml`
- Ensure firewall allows communication on required ports

## 📊 Testing

### Network Performance
```bash
# Test with iperf3
iperf3 -s  # On server
iperf3 -c <server_ip>  # On client
```

### Signal Quality
Monitor gNB logs for connection status and signal quality metrics.

## 🛡️ Security Considerations

- Change default WebUI credentials (`admin/1423`)
- Configure firewall rules for production deployment
- Restrict WebUI access to trusted networks
- Regular backup of MongoDB database and configuration files

## 📝 Regulatory Compliance

⚠️ **Important**: Ensure compliance with local regulations:
- Verify frequency band (n78) usage permissions
- Obtain necessary licenses for radio transmission
- Check power limits and antenna restrictions

## 🔗 References

- [Open5GS Documentation](https://open5gs.org/open5gs/docs/)
- [srsRAN Project Installation Guide](https://docs.srsran.com/projects/project/en/latest/user_manuals/source/installation.html)
- [Open-Cells UICC Programming](https://open-cells.com/index.php/uiccsim-programing/)
- [UHD/USRP Documentation](https://kb.ettus.com/USRP_Host_Software)

## 📄 License

This project is for educational and research purposes. Please ensure compliance with local regulations before deployment.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for improvements and bug fixes.

## 💡 Support

If you encounter issues:
1. Check the troubleshooting section
2. Review the referenced documentation
3. Open an issue with detailed logs and system information
