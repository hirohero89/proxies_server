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
    echo "Error: CURRENT_IPV6 is not set."
    exit 1
fi

# Function to generate random IPv6 suffix (last 4 blocks)
generate_ipv6_suffix() {
    printf '%x:%x:%x:%x\n' $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536))
}

# Create the directory if it doesn't exist
mkdir -p $WORKDIR

# Clear or create the temporary IPv6 file
> $TEMP_IPV6_FILE

# Generate random IPv6 addresses and store them in generated_ipv6.txt
echo "Generating and writing random IPv6 addresses to $TEMP_IPV6_FILE..."

# Count the number of occurrences of '-e' in the 3proxy config
count=$(grep -c '-e' $PROXY_CONFIG)

if [[ $count -eq 0 ]]; then
    echo "Error: No '-e' entries found in $PROXY_CONFIG."
    exit 1
fi

# Generate the required number of random IPv6 addresses
for ((i=1; i<=count; i++)); do
    RANDOM_SUFFIX=$(generate_ipv6_suffix)
    GENERATED_IPV6="$CURRENT_IPV6:$RANDOM_SUFFIX"
    echo "$GENERATED_IPV6" >> $TEMP_IPV6_FILE
done

# Check if the temporary file has content
if [[ ! -s $TEMP_IPV6_FILE ]]; then
    echo "Error: No IPv6 addresses were generated."
    exit 1
fi

# Update the IPv6 addresses after the "-e" flag in 3proxy.cfg
echo "Updating 3proxy.cfg with new IPv6 addresses..."
index=0
while read -r ipv6_address; do
    sed -i "s/-e [0-9a-f:]*\b/-e $ipv6_address/" $PROXY_CONFIG
    index=$((index + 1))
done < $TEMP_IPV6_FILE

# Update IPv6 addresses after "add" in boot_ifconfig.sh (if the file exists)
if [ -f $IFCONFIG_SCRIPT ]; then
    echo "Updating boot_ifconfig.sh with new IPv6 addresses..."
    index=0
    while read -r ipv6_address; do
        sed -i "s/add [0-9a-f:]*\b/add $ipv6_address/" $IFCONFIG_SCRIPT
        index=$((index + 1))
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
