#!/bin/bash

# Fetch the current IPv6 /64 prefix (first 4 blocks)
CURRENT_IPV6='2a01:4f8:1c1b:6f7c'

# Define the file paths
WORKDIR="/home/proxy-installer"
PROXY_CONFIG="/etc/3proxy/3proxy.cfg"
IFCONFIG_SCRIPT="${WORKDIR}/boot_ifconfig.sh"
TEMP_IPV6_FILE="${WORKDIR}/generated_ipv6.txt"

# Check if CURRENT_IPV6 is set
if [[ -z "$CURRENT_IPV6" ]]; then
    echo "Error: Unable to retrieve the current IPv6 prefix."
    exit 1
fi

# Backup existing 3proxy.cfg and boot_ifconfig.sh files
echo "Backing up configuration files..."
cp $PROXY_CONFIG ${PROXY_CONFIG}.bak
if [ -f $IFCONFIG_SCRIPT ]; then
    cp $IFCONFIG_SCRIPT ${IFCONFIG_SCRIPT}.bak
fi

# Function to generate random IPv6 suffix (last 4 blocks)
generate_ipv6_suffix() {
    printf '%x:%x:%x:%x\n' $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536))
}

# Clear or create the temporary IPv6 file
> $TEMP_IPV6_FILE

# Generate random IPv6 addresses and store them in generated_ipv6.txt
echo "Generating and writing random IPv6 addresses to $TEMP_IPV6_FILE..."
grep -oP '(?<=-e\s)[0-9a-f:]{1,39}' $PROXY_CONFIG | while read -r line; do
    RANDOM_SUFFIX=$(generate_ipv6_suffix)
    GENERATED_IPV6="$CURRENT_IPV6:$RANDOM_SUFFIX"
    echo "$GENERATED_IPV6" >> $TEMP_IPV6_FILE
done

# Read from the temp file for both 3proxy.cfg and boot_ifconfig.sh updates

# Update the IPv6 addresses after the "-e" flag in 3proxy.cfg
echo "Updating 3proxy.cfg with new IPv6 prefix and random suffix..."
while read -r ipv6_address; do
    sed -i "0,/-e\s[0-9a-f:]\+/s//-e $ipv6_address/" $PROXY_CONFIG
done < $TEMP_IPV6_FILE

# Update IPv6 addresses after "add" in boot_ifconfig.sh (if the file exists)
if [ -f $IFCONFIG_SCRIPT ]; then
    echo "Updating boot_ifconfig.sh with new IPv6 addresses..."
    while read -r ipv6_address; do
        sed -i "0,/add\s[0-9a-f:]\+/s//add $ipv6_address/" $IFCONFIG_SCRIPT
    done < $TEMP_IPV6_FILE
fi

# Verify update in 3proxy.cfg and boot_ifconfig.sh
echo "Verifying updates..."
echo "3proxy.cfg:"
grep "-e" $PROXY_CONFIG
if [ -f $IFCONFIG_SCRIPT ]; then
    echo "boot_ifconfig.sh:"
    grep "add" $IFCONFIG_SCRIPT
fi

# IPv6 addresses have been saved to generated_ipv6.txt
echo "Generated IPv6 addresses:"
cat $TEMP_IPV6_FILE

echo "IPv6 addresses updated successfully!"
