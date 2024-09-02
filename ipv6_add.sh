#!/bin/bash

# Script to configure IPv6 addresses from 3proxy.cfg to be persistent across reboots
# Reads IPv6 addresses from 3proxy.cfg and writes them to /etc/sysconfig/network-scripts/ifcfg-enp1s0

# Configuration file paths
PROXY_CONFIG="/usr/local/etc/3proxy/3proxy.cfg"
NETWORK_SCRIPT="/etc/sysconfig/network-scripts/ifcfg-enp1s0"

# Backup the original network script file
cp $NETWORK_SCRIPT $NETWORK_SCRIPT.bak

# Extract IPv6 addresses after -e from 3proxy.cfg
IPV6_ADDRESSES=$(grep -oP '(?<=-e)[0-9a-fA-F:]+(?=\s|$)' $PROXY_CONFIG)

# Check if we found any IPv6 addresses
if [ -z "$IPV6_ADDRESSES" ]; then
    echo "No IPv6 addresses found in $PROXY_CONFIG"
    exit 1
fi

# Prepare the IPV6ADDR_SECONDARIES line with /64 appended to each address
IPV6ADDR_SECONDARIES="IPV6ADDR_SECONDARIES=\"$(echo $IPV6_ADDRESSES | sed 's/$/\/64/g' | tr '\n' ' ')\""

# Remove existing IPV6ADDR_SECONDARIES line from the network script
sed -i '/^IPV6ADDR_SECONDARIES=/d' $NETWORK_SCRIPT

# Append the new IPV6ADDR_SECONDARIES line
echo $IPV6ADDR_SECONDARIES >> $NETWORK_SCRIPT

# Ensure IPv6 is enabled
if ! grep -q "^IPV6INIT=yes" $NETWORK_SCRIPT; then
    echo "IPV6INIT=yes" >> $NETWORK_SCRIPT
fi

# Restart the network service to apply changes
echo "Restarting network service..."
sudo systemctl restart network

echo "IPv6 addresses from $PROXY_CONFIG have been added to $NETWORK_SCRIPT and made persistent."
