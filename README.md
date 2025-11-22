### What is a Private 5G Network?

A private 5G network is a dedicated cellular network deployed within an organization's premises or specific geographic area. Unlike public networks operated by mobile carriers, private 5G networks offer:

- **Complete Control:** Full management of network policies, security, and quality of service
- **Customization:** Ability to optimize network for specific use cases and requirements
- **Privacy:** Data remains within the organization's infrastructure
- **Low Latency:** Reduced latency for time-sensitive applications
- **Network Slicing:** Support for multiple logical networks with different characteristics

### Guide Structure

This repository includes two main deployment approaches:

#### **1. Open5GS + UERANSIM (Software-Based Simulation)**
- **Best For:** Learning, testing, development, and lab environments
- **Requirements:** Standard Linux VMs (no specialized hardware needed)
- **Cost:** Free and open-source
- **Complexity:** Medium
- **Scalability:** Limited to CPU capacity

#### **2. srsRAN + USRP B210 (Hardware-Based)**
- **Best For:** Production testing, real radio frequency testing, actual deployment
- **Requirements:** USRP B210 software-defined radio hardware
- **Cost:** Hardware investment required
- **Complexity:** High
- **Scalability:** Limited by SDR hardware capabilities

### Key Features Covered

✅ **Complete 5G Core Network** - AMF, SMF, UPF, and other essential functions  
✅ **Network Slicing** - Support for eMBB, URLLC, and mMTC slices  
✅ **RAN Simulation** - Virtual gNodeB and User Equipment  
✅ **Database Management** - MongoDB integration for subscriber data  
✅ **Web Interface** - User-friendly WebUI for network management  
✅ **Real Hardware Support** - Optional USRP integration for live RF testing  
✅ **Comprehensive Testing** - End-to-end network validation  
✅ **Troubleshooting Guide** - Common issues and solutions  

### Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│         Public Network / Internet Access             │
└──────────────┬──────────────────────────────────────┘
               │
        ┌──────▼──────┐
        │   NAT/GW    │
        │   (Optional)│
        └──────┬──────┘
               │
    ┌──────────┼──────────┐
    │                     │
┌───▼────────────┐   ┌───▼─────────────┐
│  5G Core (VM1) │   │ RAN/UE (VM2)    │
│                │   │                 │
│ - AMF          │   │ - gNB (RAN)     │
│ - SMF          │   │ - UE1           │
│ - UPF          │   │ - UE2           │
│ - NRF          │   │ - UE3           │
│ - MongoDB      │   │                 │
│ - WebUI        │   │ (Simulated)     │
└────────────────┘   └─────────────────┘
        ▲                     │
        │        NGAP/N2      │
        │   GTP-U/N3         │
        └─────────────────────┘
```

### Network Slicing Types

The guide demonstrates three network slices, each optimized for different use cases:

| Slice | Type | Use Cases | QoS Profile |
|-------|------|-----------|------------|
| **Slice 1** | eMBB | Video streaming, data download | High bandwidth, moderate latency |
| **Slice 2** | URLLC | Remote surgery, industrial control | Low latency, high reliability |
| **Slice 3** | mMTC | IoT sensors, massive connectivity | Low bandwidth, best effort |

### Target Audience

This guide is designed for:

- **Students & Researchers** - Learning 5G concepts and architecture
- **Network Engineers** - Testing and validating 5G configurations
- **Developers** - Building and testing 5G applications
- **System Administrators** - Deploying and managing private 5G networks
- **Enterprises** - Prototyping private 5G solutions

### Quick Start Guide

Choose your deployment approach:

**Option A: Software-Only (Recommended for Learning)**
1. Read Section 1-8 in the "Open5GS + UERANSIM" guide
2. Prepare two Ubuntu 22.04 VMs
3. Follow step-by-step instructions
4. Estimated setup time: 2-3 hours

**Option B: Hardware-Based (For Production Testing)**
1. Acquire USRP B210 hardware
2. Follow the "srsRAN + USRP B210" guide
3. Configure programmable SIM cards
4. Estimated setup time: 4-6 hours (plus hardware procurement)

### Prerequisites

**Minimum Requirements:**
- Ubuntu 22.04 LTS operating system
- 4GB RAM minimum (8GB recommended)
- 20GB disk space per VM
- Network connectivity between VMs
- Basic Linux command-line knowledge

**For Hardware Deployment:**
- USRP B210 SDR (~$2000)
- Programmable SIM card
- Appropriate RF cables and antennas
- USB 3.0 connectivity

### Key Technologies & Standards

- **3GPP Standards** - 5G NR (New Radio), 5GC (5G Core)
- **Open5GS** - Open-source 5G core implementation
- **UERANSIM** - Open-source RAN simulator
- **srsRAN** - Software Radio Systems RAN implementation
- **MongoDB** - NoSQL database for network data
- **Node.js** - WebUI backend technology




# 1. Deploying a Private 5G Network (Open5GS + UERANSIM)

This guide provides a complete setup for a private 5G network using open-source components.

## 📖 Overview

This repository contains comprehensive documentation and guides for deploying a complete private 5G network infrastructure. Whether you're looking to set up a laboratory environment, develop 5G applications, or test network slicing concepts, this guide provides everything you need.

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

  ---

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

  ---

  ## 2.2 Configure UPF (User Plane Function)

  The UPF handles packet forwarding and GTP-U tunneling. Edit `/etc/open5gs/upf.yaml`:

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

  Replace `ens33` below with your external interface name (find with `ip route show default` or `ip a`).

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

  ### 4.1 Install MongoDB

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

  ### 4.2 Install Node.js and WebUI

  ```bash
  sudo apt update
  sudo apt install -y ca-certificates curl gnupg
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  NODE_MAJOR=20
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  sudo apt update
  sudo apt install -y nodejs
  curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
  ```

  ### 4.3 WebUI Access & Credentials

  **Note:** Change these credentials in production.

  - URL: http://localhost:9999
  - Username: admin
  - Password: 1423

  ### 4.4 Default Test Subscriber Values

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

  ## 7. Configure & Run UE (User Equipment)

  ### 7.1 Configure & Run UE1 (Primary UE)

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

  ### 8.1 Ping Test

  Ping via the UE TUN interface (replace `uesimtun0` with the actual TUN name shown by UERANSIM):

  ```bash
  ping -I uesimtun0 google.com
  ```

  ### 8.2 HTTP Request Test

  Curl via the UE interface:

  ```bash
  curl --interface uesimtun0 -X GET "https://httpbin.org/get"
  ```

  ---

  ## Quick Troubleshooting

  ### Troubleshooting AMF Issues

  - View AMF logs:

  ```bash
  sudo tail -f /var/log/open5gs/amf.log
  sudo journalctl -u open5gs-amf
  ```

  ### Troubleshooting MongoDB Issues

  - MongoDB:

  ```bash
  sudo journalctl -u mongod
  sudo systemctl restart mongod
  ```

  ### Troubleshooting UPF Issues

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

  
</details>


<br />
<hr>
<hr>

# 2. Deploying a Private 5G Network with Network Slicing
## (Open5GS + UERANSIM) Static Network Slicing Implementation

A comprehensive guide for deploying a complete private 5G network infrastructure using open-source components with support for network slicing (eMBB, URLLC, mMTC).


## 📋 Overview

This guide provides a complete, step-by-step implementation of a private 5G network using:

- **5G Core Network:** Open5GS (Open Source 5G Core)
- **RAN Simulator:** UERANSIM (5G RAN and UE Simulator)
- **Network Slicing:** Three dedicated slices for different service types:
  - **eMBB** (Enhanced Mobile Broadband) - High bandwidth applications
  - **URLLC** (Ultra Reliable Low Latency) - Mission-critical communications
  - **mMTC** (Massive Machine Type Communications) - IoT and sensor networks
- **Database:** MongoDB for subscriber and network policy management
- **Web Interface:** WebUI for network management and subscriber provisioning


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

  Verify the installation by checking if all Open5GS services are running:

  ```bash
  sudo systemctl status open5gs-*
  ```

  ---

  ## 2. Configure Open5GS

  ### 2.1 Configure AMF (Access and Mobility Management Function)

  The AMF handles UE registration, authentication, and connection management. Edit the AMF configuration file (`/etc/open5gs/amf.yaml`) and set the server/client addresses accordingly:

  ```bash
  sudo gedit /etc/open5gs/amf.yaml
  ```

  ```yaml
  logger:
  file:
    path: /var/log/open5gs/amf.log
    #  level: info   # fatal|error|warn|info(default)|debug|trace

    global:
    max:
        ue: 1024  # The number of UE can be increased depending on memory size.
    #    peer: 64

    amf:
    sbi:
        server:
        - address: 192.168.159.129
            port: 7777
        client:
    #      nrf:
    #        - uri: http://127.0.0.10:7777
        scp:
            - uri: http://127.0.0.200:7777
    ngap:
        server:
        - address: 192.168.159.129
    metrics:
        server:
        - address: 192.168.159.129
            port: 9090
    guami:
        - plmn_id:
            mcc: 999
            mnc: 70
        amf_id:
            region: 2
            set: 1
    tai:
        - plmn_id:
            mcc: 999
            mnc: 70
        tac: 1
    plmn_support:
        - plmn_id:
            mcc: 999
            mnc: 70
        s_nssai:
            - sst: 1
            - sst: 2
            - sst: 3
    security:
        integrity_order : [ NIA2, NIA1, NIA0 ]
        ciphering_order : [ NEA0, NEA1, NEA2 ]
    network_name:
        full: Open5GS
        short: Next
    amf_name: open5gs-amf0
    time:
    #    t3502:
    #      value: 720   # 12 minutes * 60 = 720 seconds
        t3512:
        value: 540    # 9 minutes * 60 = 540 seconds
  ```

  Restart AMF:

  ```bash
  sudo systemctl restart open5gs-amfd
  sudo tail -f /var/log/open5gs/amf.log
  ```

  ---

  ### 2.2 Configure UPF (User Plane Function)

  The UPF handles packet forwarding between gNB and external networks. It manages GTP-U tunnels and IP routing. Edit the UPF configuration file (`/etc/open5gs/upf.yaml`):

  ```bash
  sudo gedit /etc/open5gs/upf.yaml
  ```

  ```yaml
    file:
        path: /var/log/open5gs/upf.log
    #  level: info   # fatal|error|warn|info(default)|debug|trace

    global:
    max:
        ue: 1024  # Number of UEs UPF can handle

    upf:
    pfcp:
        server:
        - address: 127.0.0.7
        client:
        smf:
            - address: 127.0.0.4  # PFCP server address of SMF

    gtpu:
        server:
        - address: 192.168.159.129 # GTP-U endpoint

    session:
        - subnet: 10.45.0.0/16
        gateway: 10.45.0.1
        dnn: internet
        s_nssai:
            - sst: 1   # eMBB slice
        - subnet: 10.46.0.0/16
        gateway: 10.46.0.1
        dnn: urllc
        s_nssai:
            - sst: 2   # URLLC slice
        - subnet: 10.47.0.0/16
        gateway: 10.47.0.1
        dnn: iot
        s_nssai:
            - sst: 3   # mMTC slice

    metrics:
        server:
        - address: 192.168.159.129
            port: 9090
    ```

  Restart UPF:

  ```bash
  sudo systemctl restart open5gs-upfd
  sudo tail -f /var/log/open5gs/upf.log
  ```

  ---

  ### 2.3 Configure SMF (Session Management Function)

  The SMF manages PDU sessions, assigns IP addresses to UEs, and controls the UPF. Edit the SMF configuration file (`/etc/open5gs/smf.yaml`):

  ```bash
  sudo gedit /etc/open5gs/smf.yaml
  ```

  ```yaml
  logger:
  file:
    path: /var/log/open5gs/smf.log
    #  level: info   # fatal|error|warn|info(default)|debug|trace

    global:
    max:
        ue: 1024  # The number of UE can be increased depending on memory size.
    #    peer: 64

    smf:
    sbi:
        server:
        - address: 127.0.0.4
            port: 7777
        client:
    #      nrf:
    #        - uri: http://127.0.0.10:7777
        scp:
            - uri: http://127.0.0.200:7777

    pfcp:
        server:
        - address: 127.0.0.4
        client:
        upf:
            - address: 127.0.0.7

    gtpc:
        server:
        - address: 127.0.0.4

    gtpu:
        server:
        - address: 127.0.0.4

    metrics:
        server:
        - address: 127.0.0.4
            port: 9090

    session:
        - subnet: 10.45.0.0/16
        gateway: 10.45.0.1
        dnn: internet
        s_nssai:
            - sst: 1
        - subnet: 10.46.0.0/16
        gateway: 10.46.0.1
        dnn: urllc
        s_nssai:
            - sst: 2
        - subnet: 10.47.0.0/16
        gateway: 10.47.0.1
        dnn: iot
        s_nssai:
            - sst: 3

    dns:
        - 8.8.8.8
        - 8.8.4.4
        - 2001:4860:4860::8888
        - 2001:4860:4860::8844

    mtu: 1400
    #  p-cscf:
    #    - 127.0.0.1
    #    - ::1
    #  ctf:
    #    enabled: auto   # auto(default)|yes|no

    freeDiameter: /etc/freeDiameter/smf.conf

    info:
    - s_nssai:
        - sst: 1       # eMBB slice
            dnn:
            - internet
        - sst: 2       # URLLC slice
            dnn:
            - urllc
        - sst: 3       # mMTC slice
            dnn:
            - iot
        tai:
        - plmn_id:
            mcc: 999
            mnc: 70
            tac: 1

  ```

  Restart SMF:

  ```bash
  sudo systemctl restart open5gs-smfd
  sudo tail -f /var/log/open5gs/smf.log
  ```

  ---

  ## 3. NAT / IP Forwarding (if you want UE internet access)

  **Description:** This section configures Network Address Translation (NAT) and IP forwarding to enable UEs to access external networks (like the internet) through the Open5GS core network.

  Replace `ens33` below with your external interface name (find with `ip route show default` or `ip a`):

  ```bash
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
  sudo systemctl stop ufw
  sudo iptables -I FORWARD 1 -j ACCEPT
  sudo ip addr add 10.45.0.1/16 dev ogstun
  sudo ip addr add 10.46.0.1/16 dev ogstun
  sudo ip addr add 10.47.0.1/16 dev ogstun
  sudo ip link set ogstun up
  ```

  To persist iptables rules between reboots (Ubuntu):

  ```bash
  sudo apt install -y iptables-persistent
  sudo netfilter-persistent save
  ```

  ---

  ## 4. Install MongoDB and WebUI (on Open5GS VM)

  **Description:** MongoDB stores subscriber information and network policies. The WebUI provides a graphical interface to manage the 5G network.

  ### 4.1 Install MongoDB

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

  ### 4.2 Install Node.js and WebUI

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
  curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
  ```

  ### 4.3 WebUI Access & Default Credentials

  **Note:** Change these credentials in production environments.

  - URL: http://localhost:9999
  - Username: admin
  - Password: 1423

  ### 4.4 Default Test Subscriber Values

  These are the default test subscriber values used by UERANSIM:

  - IMSI: 901700000000001
  - Subscriber Key: 465B5CE8B199B49FAA5F0A2EE238A6BC
  - USIM type: OPc
  - Operator Key (OPC): E8ED289DEBA952E4283B54E88E6183CA

  ---

  ## 5. Install UERANSIM (VM2: 192.168.159.130)

  **Description:** UERANSIM is an open-source 5G RAN simulator and UE simulator. This section covers the installation and build process.

  ### 5.1 Install Prerequisites and Build UERANSIM

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

  **Description:** The gNB (gNodeB) is the RAN basestation. This section configures the gNB to connect to the Open5GS core network and support multiple network slices.

  ### 6.1 Edit gNB Configuration

  ```bash
  sudo gedit config/open5gs-gnb.yaml
  ```

  ```yaml
    mcc: '999'          # Mobile Country Code value
    mnc: '70'           # Mobile Network Code value (2 or 3 digits)

    nci: '0x000000010'  # NR Cell Identity (36-bit)
    idLength: 32        # NR gNB ID length in bits [22...32]
    tac: 1              # Tracking Area Code

    linkIp: 192.168.159.137  # gNB's local IP address for Radio Link Simulation (Usually same with local IP)
    ngapIp: 192.168.159.137  # gNB's local IP address for N2 Interface (Usually same with local IP)
    gtpIp: 192.168.159.137   # gNB's local IP address for N3 Interface (Usually same with local IP)

    # List of AMF address information
    amfConfigs:
    - address: 192.168.159.129
        port: 38412

    # List of supported S-NSSAIs by this gNB
    slices:
    - sst: 1
    - sst: 2
    - sst: 3

    # Indicates whether or not SCTP stream number errors should be ignored.
    ignoreStreamIds: true

  ```
 Start the gNB (from the UERANSIM directory):

  ```bash
  ./build/nr-gnb -c config/open5gs-gnb.yaml
  ```

  You should see SCTP/NGAP messages indicating NG setup success if the AMF is reachable.

  ---

  ## 7. Configure & Run UE (User Equipment)

  **Description:** UEs connect to the gNB and register with the core network. This section covers configuring and running one or multiple UEs.

  ### 7.1 Configure & Run UE1 (Primary UE)

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

  ### 7.2 Configure & Run UE2 (Optional - for Multi-Slice Testing)

  **Description:** UE2 is configured to connect to a different network slice (URLLC - Ultra Reliable Low Latency Communications).

  Edit the UE2 configuration file (located in the same folder as gNB config, `config/` directory):

  ```bash
  sudo gedit config/open5gs-ue2.yaml
  ```

  Start the second UE:

  ```bash
  sudo ./build/nr-ue -c config/open5gs-ue2.yaml
  ```

  ---

  ### 7.3 Configure & Run UE3 (Optional - for Multi-Slice Testing)

  **Description:** UE3 is configured to connect to a third network slice (mMTC - Massive Machine Type Communications).

  Edit the UE3 configuration file (located in the same folder as gNB config, `config/` directory):

  ```bash
  sudo gedit config/open5gs-ue3.yaml
  ```

  Start the third UE:

  ```bash
  sudo ./build/nr-ue -c config/open5gs-ue3.yaml
  ```
  ---

  ## 8. Test UE Internet Access

  **Description:** This section provides commands to verify that UEs can successfully access external networks and services through the 5G core.

  ### 8.1 Ping Test

  ```bash
  ping -I uesimtun0 google.com
  ping -I uesimtun1 google.com
  ping -I uesimtun2 google.com
  ```

  ### 8.2 HTTP Request Test

  Curl via the UE interface:

  ```bash
  curl --interface uesimtun0 -X GET "https://httpbin.org/get"
  ```

  ---

  ## Quick Troubleshooting

  **Description:** Common issues and their solutions when deploying and testing the 5G network.

  ### Troubleshooting AMF Issues

  - View AMF logs:

  ```bash
  sudo tail -f /var/log/open5gs/amf.log
  sudo journalctl -u open5gs-amf
  ```

  ### Troubleshooting MongoDB Issues

  - MongoDB:

  ```bash
  sudo journalctl -u mongod
  sudo systemctl restart mongod
  ```

  ### Troubleshooting UPF Issues

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

  ### What This Guide Covers

  This comprehensive guide walks you through the complete deployment of a private 5G network with the following components and features:

  #### **Core Components:**
  1. **Open5GS Core Network** - Implements 3GPP-compliant 5G core network functions (AMF, SMF, UPF)
  2. **UERANSIM** - Provides both RAN (gNB) simulation and multiple UE instances for testing
  3. **Network Slicing** - Three isolated network slices supporting different QoS requirements
  4. **MongoDB Database** - Persists subscriber information, network policies, and configuration data
  5. **WebUI** - User-friendly interface for network management and UE provisioning

  #### **Key Sections:**
  - **Section 1:** Install and verify Open5GS core network
  - **Section 2:** Configure AMF, UPF, and SMF with network slicing support
  - **Section 3:** Set up NAT and IP forwarding for external network access
  - **Section 4:** Install MongoDB and WebUI for network management
  - **Section 5:** Build UERANSIM from source
  - **Section 6:** Configure and run the gNB (RAN simulator)
  - **Section 7:** Configure and run multiple UEs with slice-specific settings
  - **Section 8:** Test UE connectivity and network functionality
  - **Troubleshooting:** Resolve common issues with logs and diagnostics

  #### **Features:**
  ✅ Complete end-to-end 5G network setup  
  ✅ Support for three network slices (eMBB, URLLC, mMTC)  
  ✅ Multiple UE support for multi-slice testing  
  ✅ Open-source and free-to-use components  
  ✅ Copy-paste friendly command blocks  
  ✅ Comprehensive troubleshooting guide  
  ✅ Windows/WSL compatible instructions  

  ### Prerequisites

  **Hardware:**
  - Two VMs or physical machines on the same network
  - Minimum 4GB RAM per VM (8GB recommended)
  - Ubuntu 22.04 LTS as the operating system

  **Network Setup:**
  - Open5GS Core: 192.168.159.129
  - UERANSIM (RAN/UE): 192.168.159.130
  - Network connectivity between the two machines

  ### Next Steps

  1. Read through the **Overview** section above to understand the architecture
  2. Prepare your VMs with Ubuntu 22.04 LTS
  3. Follow each section sequentially, starting with **Section 1**
  4. Use the **Troubleshooting** section if you encounter issues
  5. Verify network functionality using the **Testing** commands in Section 8

  ### Support & Documentation

  - [Open5GS Documentation](https://open5gs.org/)
  - [UERANSIM GitHub](https://github.com/aligungr/UERANSIM)
  - [5G Architecture Overview](https://www.3gpp.org/)

  ---

  This README was reformatted to make all commands copy-pasteable and easy to automate. For automation scripts, please refer to the deployment scripts available in the repository.

  
</details>

<br />
<hr>
<hr>

# 3.Private 5G Network Setup TestBed

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
iperf3 -c <server_ip # On client
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
