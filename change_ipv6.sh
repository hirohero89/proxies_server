#!/bin/bash

# Fetch the current IPv6 address from the system interface (e.g., eth0)
CURRENT_IPV6='2a01:4f8:1c1b:6f7c'

# Define the file paths
WORKDIR="/home/proxy-installer"
PROXY_CONFIG="/etc/3proxy/3proxy.cfg"
IPTABLES_SCRIPT="${WORKDIR}/boot_iptables.sh"
IFCONFIG_SCRIPT="${WORKDIR}/boot_ifconfig.sh"

# Check if CURRENT_IPV6 is found
if [[ -z "$CURRENT_IPV6" ]]; then
    echo "Error: Unable to retrieve the current IPv6 address."
    exit 1
fi

# Backup existing files
echo "Backing up configuration files..."
cp $PROXY_CONFIG $PROXY_CONFIG.bak
cp $IPTABLES_SCRIPT $IPTABLES_SCRIPT.bak
if [ -f $IFCONFIG_SCRIPT ]; then
    cp $IFCONFIG_SCRIPT $IFCONFIG_SCRIPT.bak
fi

# Update IPv6 prefix in 3proxy.cfg
echo "Updating 3proxy.cfg with new IPv6 prefix..."
sed -i "s/:[0-9a-f]\{1,4\}:[0-9a-f]\{1,4\}:[0-9a-f]\{1,4\}:[0-9a-f]\{1,4\}/:$CURRENT_IPV6/g" $PROXY_CONFIG

# Update IPv6 prefix in boot_iptables.sh
echo "Updating boot_iptables.sh with new IPv6 prefix..."
sed -i "s/:[0-9a-f]\{1,4\}:[0-9a-f]\{1,4\}:[0-9a-f]\{1,4\}:[0-9a-f]\{1,4\}/:$CURRENT_IPV6/g" $IPTABLES_SCRIPT

# Update IPv6 prefix in boot_ifconfig.sh (if the file exists)
if [ -f $IFCONFIG_SCRIPT ]; then
    echo "Updating boot_ifconfig.sh with new IPv6 prefix..."
    sed -i "s/:[0-9a-f]\{1,4\}:[0-9a-f]\{1,4\}:[0-9a-f]\{1,4\}:[0-9a-f]\{1,4\}/:$CURRENT_IPV6/g" $IFCONFIG_SCRIPT
fi

# Verify updates
echo "Verifying updates..."
grep -E ":[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}" $PROXY_CONFIG
grep -E ":[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}" $IPTABLES_SCRIPT
if [ -f $IFCONFIG_SCRIPT ]; then
    grep -E ":[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}" $IFCONFIG_SCRIPT
fi

echo "IPv6 prefix updated successfully!"
