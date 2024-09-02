#!/bin/bash

# Script Name: ipv6_proxies_server.sh
# Description: This script sets up multiple IPv6 proxies using 3proxy on AlmaLinux, opens the necessary ports, and restarts the NetworkManager.

# Variables
CONFIG_FILE="/usr/local/etc/3proxy/3proxy.cfg"
START_PORT=10000

# Function to generate random hexadecimal values
generate_random_hex() {
    printf "%x" $((RANDOM % 65536))
}

# Get the server's base IPv4 address
BASE_IPV4=$(hostname -I | awk '{print $1}')

# Get the server's base IPv6 address (excluding the interface identifier)
BASE_IPV6=$(ip -6 addr | grep 'global' | grep -v 'temporary' | awk '{print $2}' | cut -d'/' -f1 | head -n 1 | cut -d':' -f1-4)

# Automatically detect the network interface
INTERFACE=$(ip -6 route | grep default | awk '{print $5}')

if [ -z "$BASE_IPV4" ] || [ -z "$BASE_IPV6" ] || [ -z "$INTERFACE" ]; then
    echo "Failed to retrieve base IPv4, IPv6 address, or network interface. Please check your network configuration."
    exit 1
fi

# Get the number of proxies from user input
read -p "Enter the number of proxies to create: " NUM_PROXIES

# Update system and install 3proxy
echo "Updating system and installing 3proxy..."
yum update -y
yum install -y 3proxy

# Create 3proxy configuration directory if it doesn't exist
mkdir -p /usr/local/etc/3proxy

# Create 3proxy configuration file with base settings
cat <<EOL > $CONFIG_FILE
# 3proxy base configuration
daemon
maxconn 1000
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
flush
auth none
EOL

# Loop to generate the specified number of proxies, add them to the server, and open the ports
for (( i=0; i<$NUM_PROXIES; i++ ))
do
    PORT=$((START_PORT + i))
    RAND1=$(generate_random_hex)
    RAND2=$(generate_random_hex)
    RAND3=$(generate_random_hex)
    RAND4=$(generate_random_hex)

    IPV6_ADDRESS="$BASE_IPV6:$RAND1:$RAND2:$RAND3:$RAND4"

    # Add the generated IPv6 address to the server
    sudo ip -6 addr add $IPV6_ADDRESS/64 dev $INTERFACE

    # Add proxy configuration to 3proxy config file
    cat <<EOL >> $CONFIG_FILE
auth none
allow *
proxy -6 -n -a -p$PORT -i$BASE_IPV4 -e$IPV6_ADDRESS
flush
EOL

    # Open the port in the firewall using firewalld
    sudo firewall-cmd --zone=public --add-port=$PORT/tcp --permanent
done

# Reload the firewall to apply the new rules
sudo firewall-cmd --reload

# Save iptables rules (optional if using firewalld)
sudo service iptables save
sudo service ip6tables save

# Restart NetworkManager to apply network changes
echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager

# Enable and start 3proxy service
echo "Enabling and starting 3proxy service..."
systemctl enable 3proxy
systemctl start 3proxy

# Display status of 3proxy service
systemctl status 3proxy

echo "IPv6 proxy server setup completed with $NUM_PROXIES proxies starting from port $START_PORT."
echo "Base IPv4: $BASE_IPV4"
echo "Base IPv6: $BASE_IPV6"
echo "Network Interface: $INTERFACE"
