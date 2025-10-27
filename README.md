# Deploying a Private 5G Network (Open5GS + UERANSIM)

> This guide provides a complete setup for a private 5G network using open-source components.

<details>
  <summary>📚 Detailed Setup Instructions (Click to Expand)</summary>
  
  This README has been reformatted for easy copy-paste into a terminal. All shell commands are placed in fenced code blocks (bash). If you're on Windows, use WSL/Ubuntu or adapt commands for PowerShell where noted.
  
  ### Quick Links
  - [Core Network Setup](#1-install-open5gs-vm1-192168159129)
  - [UERANSIM Setup](#5-install-ueransim-vm2-192168159130)
  - [Testing](#8-test-ue-internet-access)
  - [Troubleshooting](#quick-troubleshooting)

  Requirements:
  - Two VMs (or two hosts on the same network):
    - Open5GS core: 192.168.159.129
    - UERANSIM (RAN/UE): 192.168.159.130

  ---

  ## 1. Install Open5GS (VM1: 192.168.159.129)

  Run the following on the Open5GS VM (Ubuntu 22.04):

  ```bash
  sudo apt update
  sudo apt install -y software-properties-common
  sudo add-apt-repository ppa:open5gs/latest
  sudo apt update
  sudo apt install -y open5gs
  ```

  ## 2. Configure Open5GS

  Edit AMF configuration (`/etc/open5gs/amf.yaml`) and set the server/client addresses accordingly. Example snippet:
  ```bash
  sudo gedit /etc/open5gs/amf.yaml
  ```

  ```yaml
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
  ```

  Restart AMF:

  ```bash
  sudo systemctl restart open5gs-amfd
  sudo tail -f /var/log/open5gs/amf.log
  ```

  If you need to configure UPF, edit `/etc/open5gs/upf.yaml` (or correct file) and set addresses such as:

  ```bash
  sudo gedit /etc/open5gs/upf.yaml
  ```

  ```yaml
  upf:
    pfcp:
      - addr: 127.0.0.7
    gtpu:
      - addr: 192.168.159.130
  ```

  Restart UPF:

  ```bash
  sudo systemctl restart open5gs-upfd
  sudo tail -f /var/log/open5gs/upf.log
  ```

  ---

  ## 3. NAT / IP Forwarding (if you want UE internet access)

  Replace `ens33` below with your external interface name (find with `ip route show default`).

  ```bash
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
  sudo systemctl stop ufw
  sudo iptables -I FORWARD 1 -j ACCEPT
  ```

  To persist iptables rules between reboots (Ubuntu):

  ```bash
  sudo apt install -y iptables-persistent
  sudo netfilter-persistent save
  ```

  ---

  ## 4. Install MongoDB and WebUI (on Open5GS VM)

  Install MongoDB (example for Ubuntu Jammy):

  ```bash
  sudo apt update
  sudo apt install -y gnupg
  curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
  echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
  sudo apt update
  sudo apt install -y mongodb-org
  sudo systemctl start mongod
  sudo systemctl enable mongod
  sudo systemctl status mongod
  ```

  Install Node.js and the Open5GS WebUI:

  ```bash
  sudo apt update
  sudo apt install -y ca-certificates curl gnupg
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  NODE_MAJOR=20
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  sudo apt update
  sudo apt install -y nodejs

  # Install WebUI (script from Open5GS)
  curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
  ```

  WebUI default access (change credentials in production):

  - URL: http://localhost:9999
  - Username: admin
  - Password: 1423

  Default test subscriber values (found in UERANSIM configs):

  - IMSI: 901700000000001
  - Subscriber Key: 465B5CE8B199B49FAA5F0A2EE238A6BC
  - USIM type: OPc
  - Operator Key (OPC): E8ED289DEBA952E4283B54E88E6183CA

  ---

  ## 5. Install UERANSIM (VM2: 192.168.159.130)

  Install prerequisites and build UERANSIM on the RAN/UE VM:

  ```bash
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y make g++ libsctp-dev lksctp-tools iproute2
  sudo snap install cmake --classic

  git clone https://github.com/aligungr/UERANSIM
  cd UERANSIM
  make
  ```

  ---

  ## 6. Configure gNB (example config: `config/open5gs-gnb.yaml`)

  Edit `config/open5gs-gnb.yaml` and set local IPs and AMF address:

  ```bash
  sudo gedit config/open5gs-gnb.yaml
  ```

  ```yaml
  linkIp: 192.168.159.130
  ngapIp: 192.168.159.130
  gtpIp: 192.168.159.130
  amfConfigs:
    - address: 192.168.159.129
      port: 38412
  ```

  Start the gNB (from the UERANSIM directory):

  ```bash
  ./build/nr-gnb -c config/open5gs-gnb.yaml
  ```

  You should see SCTP/NGAP messages indicating NG setup success if the AMF is reachable.

  ---

  ## 7. Configure & Run UE (example config: `config/open5gs-ue.yaml`)

  Edit `config/open5gs-ue.yaml` to use the test subscriber values and gNB search list:

  ```bash
  sudo gedit config/open5gs-ue.yaml
  ```

  ```yaml
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
  ```

  Start the UE (from UERANSIM directory):

  ```bash
  sudo ./build/nr-ue -c config/open5gs-ue.yaml
  ```

  If successful, you'll see logs indicating registration, PDU session establishment, and a TUN interface (e.g., `uesimtun0, 10.45.0.5`).

  ---

  ## 8. Test UE Internet Access

  Ping via the UE TUN interface (replace `uesimtun0` with the actual TUN name shown by UERANSIM):

  ```bash
  ping -I uesimtun0 google.com
  ```

  Curl via the UE interface:

  ```bash
  curl --interface uesimtun0 -X GET "https://httpbin.org/get"
  ```

  ---

  ## Quick Troubleshooting

  - View AMF logs:

  ```bash
  sudo tail -f /var/log/open5gs/amf.log
  sudo journalctl -u open5gs-amf
  ```

  - MongoDB:

  ```bash
  sudo journalctl -u mongod
  sudo systemctl restart mongod
  ```

  - Verify UPF logs:

  ```bash
  sudo tail -f /var/log/open5gs/upf.log
  ```

  ---

  ## Notes for Windows users

  - If you're on Windows, run these steps inside WSL (Ubuntu) for best compatibility. Some commands (like `snap`, `systemctl`, `iptables`) require a Linux environment.
  - If you must run from PowerShell, consider using `wsl` to invoke commands, e.g.:

  ## 🔗 References

  - [Documentation](https://medium.com/rahasak/5g-core-network-setup-with-open5gs-and-ueransim-cd0e77025fd7)

  ---

  ## Summary

  This README was reformatted to make commands copy-pasteable. If you'd like a separate `script.sh` with the command sequence (for automation/testing), tell me which sections you want scripted and I will add it.

  
> </details>





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
