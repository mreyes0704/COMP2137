#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-verbose]" >&2
    exit 1
}

# Initialize variable
verbose_flag=""

# Parse command line options
while [ "$#" -gt 0 ]; do
    case "$1" in
        -verbose )
            verbose_flag="-verbose"
            shift
            ;;
        * )
            usage
            ;;
    esac
done

# Transfer and run configure-host.sh script on server1-mgmt
scp configure-host.sh remoteadmin@server1-mgmt:/root || { echo "Error: Failed to transfer script to server1-mgmt"; exit 1; }
ssh remoteadmin@server1-mgmt -- /root/configure-host.sh $verbose_flag -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4 || { echo "Error: Failed to execute script on server1-mgmt"; exit 1; }

# Transfer and run configure-host.sh script on server2-mgmt
scp configure-host.sh remoteadmin@server2-mgmt:/root || { echo "Error: Failed to transfer script to server2-mgmt"; exit 1; }
ssh remoteadmin@server2-mgmt -- /root/configure-host.sh $verbose_flag -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3 || { echo "Error: Failed to execute script on server2-mgmt"; exit 1; }

# Update local /etc/hosts file
./configure-host.sh $verbose_flag -hostentry loghost 192.168.16.3 || { echo "Error: Failed to update local /etc/hosts file"; exit 1; }
./configure-host.sh $verbose_flag -hostentry webhost 192.168.16.4 || { echo "Error: Failed to update local /etc/hosts file"; exit 1; }

echo "Configuration deployment completed successfully."

