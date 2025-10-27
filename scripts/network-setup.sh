#!/bin/bash
# Network configuration script

echo "Setting up network configuration..."

# Get interface name
IFACE=$(ip route show default | awk '/default/ {print $5}')
echo "Detected interface: $IFACE"

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Configure NAT
sudo iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
sudo systemctl stop ufw
sudo iptables -I FORWARD 1 -j ACCEPT

# Make rules persistent
sudo apt install -y iptables-persistent
sudo netfilter-persistent save

echo "Network configuration complete!"