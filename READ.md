# Deploying a Private 5G Network with Network Slicing
## (Open5GS + UERANSIM) Static Network Slicing Implementation

> A comprehensive guide for deploying a complete private 5G network infrastructure using open-source components with support for network slicing (eMBB, URLLC, mMTC).

---

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

---

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
  > sudo apt update
  > sudo apt install -y software-properties-common
  > sudo add-apt-repository ppa:open5gs/latest
  > sudo apt update
  > sudo apt install -y open5gs
  ```

  Verify the installation by checking if all Open5GS services are running:

  ```bash
  > sudo systemctl status open5gs-*
  ```

  ---

  ## 2. Configure Open5GS

  ### 2.1 Configure AMF (Access and Mobility Management Function)

  The AMF handles UE registration, authentication, and connection management. Edit the AMF configuration file (`/etc/open5gs/amf.yaml`) and set the server/client addresses accordingly:

  ```bash
  > sudo gedit /etc/open5gs/amf.yaml
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
  > sudo systemctl restart open5gs-amfd
  > sudo tail -f /var/log/open5gs/amf.log
  ```

  ---

  ### 2.2 Configure UPF (User Plane Function)

  The UPF handles packet forwarding between gNB and external networks. It manages GTP-U tunnels and IP routing. Edit the UPF configuration file (`/etc/open5gs/upf.yaml`):

  ```bash
  > sudo gedit /etc/open5gs/upf.yaml
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
  > sudo systemctl restart open5gs-upfd
  > sudo tail -f /var/log/open5gs/upf.log
  ```

  ---

  ### 2.3 Configure SMF (Session Management Function)

  The SMF manages PDU sessions, assigns IP addresses to UEs, and controls the UPF. Edit the SMF configuration file (`/etc/open5gs/smf.yaml`):

  ```bash
  > sudo gedit /etc/open5gs/smf.yaml
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
  > sudo systemctl restart open5gs-smfd
  > sudo tail -f /var/log/open5gs/smf.log
  ```

  ---

  ## 3. NAT / IP Forwarding (if you want UE internet access)

  **Description:** This section configures Network Address Translation (NAT) and IP forwarding to enable UEs to access external networks (like the internet) through the Open5GS core network.

  Replace `ens33` below with your external interface name (find with `ip route show default` or `ip a`):

  ```bash
  > sudo sysctl -w net.ipv4.ip_forward=1
  > sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
  > sudo systemctl stop ufw
  > sudo iptables -I FORWARD 1 -j ACCEPT
  > sudo ip addr add 10.45.0.1/16 dev ogstun
  > sudo ip addr add 10.46.0.1/16 dev ogstun
  > sudo ip addr add 10.47.0.1/16 dev ogstun
  > sudo ip link set ogstun up
  ```

  To persist iptables rules between reboots (Ubuntu):

  ```bash
  > sudo apt install -y iptables-persistent
  > sudo netfilter-persistent save
  ```

  ---

  ## 4. Install MongoDB and WebUI (on Open5GS VM)

  **Description:** MongoDB stores subscriber information and network policies. The WebUI provides a graphical interface to manage the 5G network.

  ### 4.1 Install MongoDB

  ```bash
  > sudo apt update
  > sudo apt install -y gnupg
  > curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
  > echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
  > sudo apt update
  > sudo apt install -y mongodb-org
  > sudo systemctl start mongod
  > sudo systemctl enable mongod
  > sudo systemctl status mongod
  ```

  ### 4.2 Install Node.js and WebUI

  Install Node.js and the Open5GS WebUI:

  ```bash
  > sudo apt update
  > sudo apt install -y ca-certificates curl gnupg
  > sudo mkdir -p /etc/apt/keyrings
  > curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  > NODE_MAJOR=20
  > echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  > sudo apt update
  > sudo apt install -y nodejs
  > curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
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
  > sudo apt update
  > sudo apt upgrade -y
  > sudo apt install -y make g++ libsctp-dev lksctp-tools iproute2
  > sudo snap install cmake --classic
  > git clone https://github.com/aligungr/UERANSIM
  > cd UERANSIM
  > make
  ```

  ---

  ## 6. Configure gNB (example config: `config/open5gs-gnb.yaml`)

  **Description:** The gNB (gNodeB) is the RAN basestation. This section configures the gNB to connect to the Open5GS core network and support multiple network slices.

  ### 6.1 Edit gNB Configuration

  ```bash
  > sudo gedit config/open5gs-gnb.yaml
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
  > ./build/nr-gnb -c config/open5gs-gnb.yaml
  ```

  You should see SCTP/NGAP messages indicating NG setup success if the AMF is reachable.

  ---

  ## 7. Configure & Run UE (User Equipment)

  **Description:** UEs connect to the gNB and register with the core network. This section covers configuring and running one or multiple UEs.

  ### 7.1 Configure & Run UE1 (Primary UE)

  ```bash
  > sudo gedit config/open5gs-ue.yaml
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
  > sudo ./build/nr-ue -c config/open5gs-ue.yaml
  ```

  If successful, you'll see logs indicating registration, PDU session establishment, and a TUN interface (e.g., `uesimtun0, 10.45.0.5`).

  ---

  ### 7.2 Configure & Run UE2 (Optional - for Multi-Slice Testing)

  **Description:** UE2 is configured to connect to a different network slice (URLLC - Ultra Reliable Low Latency Communications).

  Edit the UE2 configuration file (located in the same folder as gNB config, `config/` directory):

  ```bash
  > sudo gedit config/open5gs-ue2.yaml
  ```

  Start the second UE:

  ```bash
  > sudo ./build/nr-ue -c config/open5gs-ue2.yaml
  ```

  ---

  ### 7.3 Configure & Run UE3 (Optional - for Multi-Slice Testing)

  **Description:** UE3 is configured to connect to a third network slice (mMTC - Massive Machine Type Communications).

  Edit the UE3 configuration file (located in the same folder as gNB config, `config/` directory):

  ```bash
  > sudo gedit config/open5gs-ue3.yaml
  ```

  Start the third UE:

  ```bash
  > sudo ./build/nr-ue -c config/open5gs-ue3.yaml
  ```
  ---

  ## 8. Test UE Internet Access

  **Description:** This section provides commands to verify that UEs can successfully access external networks and services through the 5G core.

  ### 8.1 Ping Test

  ```bash
  > ping -I uesimtun0 google.com
  > ping -I uesimtun1 google.com
  > ping -I uesimtun2 google.com
  ```

  ### 8.2 HTTP Request Test

  Curl via the UE interface:

  ```bash
  > curl --interface uesimtun0 -X GET "https://httpbin.org/get"
  ```

  ---

  ## Quick Troubleshooting

  **Description:** Common issues and their solutions when deploying and testing the 5G network.

  ### Troubleshooting AMF Issues

  - View AMF logs:

  ```bash
  > sudo tail -f /var/log/open5gs/amf.log
  > sudo journalctl -u open5gs-amf
  ```

  ### Troubleshooting MongoDB Issues

  - MongoDB:

  ```bash
  > sudo journalctl -u mongod
  > sudo systemctl restart mongod
  ```

  ### Troubleshooting UPF Issues

  - Verify UPF logs:

  ```bash
  > sudo tail -f /var/log/open5gs/upf.log
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

  
> </details>