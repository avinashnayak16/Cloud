#!/bin/bash
# UERANSIM setup script

echo "Starting UERANSIM setup..."

# Install prerequisites
sudo apt update
sudo apt upgrade -y
sudo apt install -y make g++ libsctp-dev lksctp-tools iproute2
sudo snap install cmake --classic

# Clone and build UERANSIM
git clone https://github.com/aligungr/UERANSIM
cd UERANSIM
make

echo "UERANSIM setup complete!"