# Quick Start Scripts for 5G Network Setup

This directory contains automated scripts for setting up a 5G network using Open5GS and UERANSIM.

## Scripts Overview

1. `launch.sh` - Main launcher script with interactive menu
2. `core-setup.sh` - Installs Open5GS Core and dependencies
3. `ueransim-setup.sh` - Installs UERANSIM and dependencies
4. `network-setup.sh` - Configures network/NAT settings
5. `config-templates.sh` - Generates configuration files

## Quick Start

1. Make scripts executable:
```bash
chmod +x *.sh
```

2. Run the launcher:
```bash
./launch.sh
```

3. Follow the interactive menu to:
   - Install Open5GS Core (on VM1)
   - Setup network configuration (on VM1)
   - Install UERANSIM (on VM2)
   - Generate configuration files
   - View logs

## IP Configuration

Default IPs (modify in config-templates.sh if needed):
- Open5GS Core: 192.168.159.129
- UERANSIM: 192.168.159.130

## WebUI Access

After core setup:
- URL: http://localhost:9999
- Username: admin
- Password: 1423