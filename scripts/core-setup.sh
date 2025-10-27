#!/bin/bash
# Open5GS Core setup script

echo "Starting Open5GS Core setup..."

# Install Open5GS
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install -y open5gs

# Install MongoDB
sudo apt update
sudo apt install -y gnupg
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# Install Node.js and WebUI
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

echo "Core setup complete! WebUI available at http://localhost:9999 (admin/1423)"