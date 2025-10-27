#!/bin/bash
# VM1 - Open5GS Core Setup Script
# Run this on the Open5GS VM (192.168.159.129)

echo "Setting up Open5GS Core (VM1)..."

# Install dependencies
sudo apt update
sudo apt install -y software-properties-common gnupg curl wget

# Install Open5GS
sudo add-apt-repository ppa:open5gs/latest -y
sudo apt update
sudo apt install -y open5gs

# Install MongoDB
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# Install Node.js and WebUI
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -

# Configure networking
sudo sysctl -w net.ipv4.ip_forward=1
IFACE=$(ip route show default | awk '/default/ {print $5}')
sudo iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
sudo systemctl stop ufw
sudo iptables -I FORWARD 1 -j ACCEPT

# Make iptables persistent
sudo apt install -y iptables-persistent
sudo netfilter-persistent save

echo "Setup complete! Access WebUI at http://localhost:9999 (admin/1423)"