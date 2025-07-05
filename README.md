# Cloud
Setup Guide for Private 5G Network
Table of Contents

Introduction
Components Required
5G Core Setup (Open5GS)
Prerequisites
MongoDB Installation
Open5GS Installation
WebUI Setup
NAT Port Forwarding


RAN Setup (srsRAN Project)
Prerequisites
Build and Installation
Configuration


Programmable SIM (Open-Cells)
Prerequisites
Compilation and Programming


USRP B210 Setup
Installation
Verification


Starting the Private 5G Network
Core Verification and Subscriber Configuration
USRP Verification
RAN Configuration and Execution


Troubleshooting
Additional Considerations
References


1. Introduction
This document provides a step-by-step guide to set up a private 5G network using open-source software and hardware. The setup includes a 5G core (Open5GS), Radio Access Network (RAN) with srsRAN, a programmable SIM card, and a USRP B210 software-defined radio (SDR) on Ubuntu 22.04 LTS.

2. Components Required

Hardware:
PC with Intel i7 processor, 32GB RAM, running Ubuntu 22.04 LTS
USRP B210 (connected via USB 3.0)
Programmable SIM card and USB card reader


Software:
5G Core: Open5GS
RAN: srsRAN Project
Programmable SIM: Open-Cells UICC tools
Dependencies: MongoDB, Node.js, UHD library


Network:
Stable internet connection for package downloads
Configured network interface for NAT forwarding




3. 5G Core Setup (Open5GS)
3.1 Prerequisites

Ubuntu 22.04 LTS installed
Root or sudo access
Internet connectivity for package installation

3.2 MongoDB Installation
MongoDB is required as the database for Open5GS.
sudo apt update
sudo apt install -y gnupg
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
sudo systemctl status mongod

Verification: Ensure MongoDB is running (status should show active).
3.3 Open5GS Installation
Install Open5GS using the package manager.
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install -y open5gs
sudo systemctl status open5gs-*

Verification: Confirm all 17 Open5GS services are active.
sudo systemctl status open5gs-* | grep -c "active"

3.4 WebUI Setup
The Open5GS WebUI requires Node.js.
Install Node.js
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs

Install WebUI
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -

Access WebUI:

URL: http://localhost:9999
Username: admin
Password: 1423

3.5 NAT Port Forwarding
Enable IP forwarding and configure NAT to connect the 5G core to the internet.
sudo sysctl -w net.ipv4.ip_forward=1
ip a  # Identify network interface (e.g., eth0)
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  # Replace eth0 with your interface
sudo iptables -t nat -A POSTROUTING -o $(ip route show default | awk '/default/ {print $5}') -j MASQUERADE
sudo systemctl stop ufw
sudo ufw status  # Should show inactive
sudo iptables -I FORWARD 1 -j ACCEPT

Note: To persist iptables rules after reboot, install iptables-persistent:
sudo apt install -y iptables-persistent
sudo dpkg-reconfigure iptables-persistent


4. RAN Setup (srsRAN Project)
4.1 Prerequisites
Install build tools and dependencies.
sudo apt update
sudo apt install -y cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev libuhd-dev uhd-host

4.2 Build and Installation
Clone and build srsRAN.
git clone https://github.com/srsRAN/srsRAN_Project.git
cd srsRAN_Project
mkdir build
cd build
cmake ../
make -j $(nproc)
make test -j $(nproc)
sudo make install
sudo cp ../configs/gnb_rf_b200_tdd_n78_20mhz.yml ./apps/gnb/gnb_rf_b200_tdd_n78_20mhz.yml

4.3 Configuration
Edit the gNB configuration file: gnb_rf_b200_tdd_n78_20mhz.yml.
cd apps/gnb/
sudo nano gnb_rf_b200_tdd_n78_20mhz.yml

Update the following sections:
cu_cp:
  amf:
    addr: 127.0.0.5                # AMF address (match Open5GS config)
    port: 38412
    bind_addr: 127.0.0.5           # Local IP for gNB
    supported_tracking_areas:
      - tac: 7
        plmn_list:
          - plmn: "99970"
            tai_slice_support_list:
              - sst: 1
  inactivity_timer: 7200

cell_cfg:
  dl_arfcn: 632628
  band: 78
  channel_bandwidth_MHz: 20
  common_scs: 30
  plmn: "99970"
  tac: 7
  pci: 1

Save and exit.

5. Programmable SIM (Open-Cells)
5.1 Prerequisites

Programmable SIM card
USB card reader
Downloaded UICC tools: uicc-v3.3.tgz

5.2 Compilation and Programming
Extract and compile the UICC tools.
tar -xvzf uicc-v3.3.tgz
cd uicc-v3.3
make

Insert the SIM card into the reader and connect it to a USB port. Program the SIM:
sudo ./program_uicc --adm 12345678 --imsi 999700000000001 --isdn 00000001 --acc 0001 --key 6874736969202073796d4b2079650a73 --opc 504f20634f6320504f50206363500a4f --spn "CSE" --authenticate --noreadafter

Verification:

Read basic card data:

sudo ./program_uicc


Enable detailed traces:

sudo DEBUG=y ./program_uicc


View parameters help:

sudo ./program_uicc --help


6. USRP B210 Setup
6.1 Installation
Install the UHD library and download firmware images.
sudo apt update
sudo apt install -y libuhd-dev uhd-host
sudo python3 /usr/lib/uhd/utils/uhd_images_downloader.py

6.2 Verification
Connect the USRP B210 to a USB 3.0 port and verify connectivity.
uhd_find_devices  # Lists connected UHD devices
uhd_usrp_probe    # Displays detailed device information

Troubleshooting: If errors occur, reconnect the USRP or verify USB 3.0 connection.

7. Starting the Private 5G Network
7.1 Core Verification and Subscriber Configuration

Restart and verify Open5GS services:

sudo systemctl restart open5gs-*
sudo systemctl status open5gs-* | grep -c "active"


Access the WebUI (http://localhost:9999, username: admin, password: 1423) and add a new subscriber:
IMSI: 999700000000001
Key: 6874736969202073796d4b2079650a73
OPC: 504f20634f6320504f50206363500a4f
DNN Configuration: Enable IPv4 (e.g., APN: internet, IP allocation: dynamic)
Save the configuration.



7.2 USRP Verification
Verify the USRP B210 is connected and operational:
uhd_find_devices
uhd_usrp_probe

Troubleshooting: If the USRP is not detected, ensure it is connected to a USB 3.0 port and re-run the commands.
7.3 RAN Configuration and Execution

Navigate to the gNB directory and run the gNB:

cd srsRAN_Project/build/apps/gnb/
sudo ./gnb -c gnb_rf_b200_tdd_n78_20mhz.yml


Verify the gNB connects to the Open5GS core and is operational (logs should indicate a successful AMF connection).

Note: Ensure the programmable SIM is inserted into a compatible 5G device to test connectivity.

8. Troubleshooting

MongoDB not running:
Check logs: sudo journalctl -u mongod
Ensure sufficient disk space and correct permissions.


Open5GS services not active:
Restart services: sudo systemctl restart open5gs-*
Check logs in /var/log/open5gs/.


USRP B210 not detected:
Verify USB 3.0 connection.
Reinstall UHD drivers: sudo apt install --reinstall libuhd-dev uhd-host.


gNB fails to connect to AMF:
Verify IP addresses and ports in gnb_rf_b200_tdd_n78_20mhz.yml.
Check Open5GS AMF configuration (/etc/open5gs/amf.yaml).


SIM programming issues:
Ensure the USB card reader is functional.
Use DEBUG=y for detailed logs during programming.




9. Additional Considerations

Security:
Change the default WebUI password (admin/1423) after setup.
Restrict WebUI access to trusted networks (e.g., configure a firewall).


Performance:
Ensure the PC has adequate cooling for continuous operation.
Monitor CPU and memory usage during gNB operation.


Regulatory Compliance:
Verify that the frequency band (n78) and ARFCN comply with local regulations.
Obtain necessary licenses for radio transmission.


Testing:
Use a 5G-capable device with the programmed SIM to test end-to-end connectivity.
Tools like iperf can measure network performance.


Backup:
Back up Open5GS database (mongodump) and configuration files regularly.




10. References

Open5GS Documentation: https://open5gs.org/open5gs/docs/
srsRAN Project Installation Guide: https://docs.srsran.com/projects/project/en/latest/user_manuals/source/installation.html
Open-Cells UICC Programming: https://open-cells.com/index.php/uiccsim-programing/
UHD/USRP Documentation: https://kb.ettus.com/USRP_Host_Software
