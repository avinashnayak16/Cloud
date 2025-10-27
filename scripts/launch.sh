#!/bin/bash
# Main launcher script for 5G network setup

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}5G Network Setup Launcher${NC}\n"

# Function to check if script exists and is executable
check_script() {
    if [ ! -x "$1" ]; then
        chmod +x "$1"
    fi
}

# Make all scripts executable
for script in *.sh; do
    [ "$script" = "launch.sh" ] && continue
    check_script "$script"
done

PS3='Please select an option: '
options=(
    "Install Open5GS Core (VM1)"
    "Setup Network/NAT (VM1)"
    "Install UERANSIM (VM2)"
    "Generate Config Files"
    "View Logs"
    "Quit"
)

select opt in "${options[@]}"
do
    case $opt in
        "Install Open5GS Core (VM1)")
            echo -e "\n${GREEN}Starting Open5GS Core installation...${NC}"
            ./core-setup.sh
            ;;
        "Setup Network/NAT (VM1)")
            echo -e "\n${GREEN}Configuring network...${NC}"
            ./network-setup.sh
            ;;
        "Install UERANSIM (VM2)")
            echo -e "\n${GREEN}Starting UERANSIM installation...${NC}"
            ./ueransim-setup.sh
            ;;
        "Generate Config Files)")
            echo -e "\n${GREEN}Generating configuration files...${NC}"
            ./config-templates.sh
            ;;
        "View Logs")
            echo -e "\n${GREEN}Available logs:${NC}"
            echo "1. AMF logs"
            echo "2. UPF logs"
            echo "3. MongoDB logs"
            read -p "Select log to view (1-3): " log_choice
            case $log_choice in
                1) sudo tail -f /var/log/open5gs/amf.log ;;
                2) sudo tail -f /var/log/open5gs/upf.log ;;
                3) sudo journalctl -u mongod ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
        "Quit")
            break
            ;;
        *) 
            echo "Invalid option $REPLY"
            ;;
    esac
done