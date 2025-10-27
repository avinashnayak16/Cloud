#!/bin/bash
# VM2 - UERANSIM Setup Script
# Run this on the UERANSIM VM (192.168.159.130)

echo "Setting up UERANSIM (VM2)..."

# Install dependencies
sudo apt update
sudo apt upgrade -y
sudo apt install -y make g++ libsctp-dev lksctp-tools iproute2 git
sudo snap install cmake --classic

# Clone and build UERANSIM
git clone https://github.com/aligungr/UERANSIM
cd UERANSIM
make

echo "UERANSIM build complete!"