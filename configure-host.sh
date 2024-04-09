#!/bin/bash

# Function to handle signals
trap '' SIGTERM SIGINT SIGHUP

# Function to log changes
log_changes() {
    logger -t configure-host "$1"
}

# Function to display error message and exit
display_error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to display usage information
usage() {
    echo "Usage: $0 [-verbose] (-name myhost | -ip 192.168.16.20 | -hostentry myhost 192.168.16.20)" >&2
    exit 1
}

# Initialize variables
verbose=0

# Parse command line options
while [ "$#" -gt 0 ]; do
    case "$1" in
        -verbose )
            verbose=1
            shift
            ;;
        -name )
            setting="name"
            desired_name="$2"
            shift 2
            ;;
        -ip )
            setting="ip"
            desired_ip="$2"
            shift 2
            ;;
        -hostentry )
            setting="hostentry"
            desired_name="$2"
            desired_ip="$3"
            shift 3
            ;;
        * )
            usage
            ;;
    esac
done

# Function to configure name
configure_name() {
    current_name=$(hostname)
    if [ "$current_name" != "$myhost" ]; then
        echo "$myhost" > /etc/hostname
        hostname "$myhost"
        log_changes "Changed hostname to '$myhost'"
    fi
}

# Function to configure IP address
configure_ip() {
    current_ip=$(hostname -I | awk '{print $1}')
    if [ "$current_ip" != "$192.168.16.20" ]; then
        sed -i "/$current_ip/c\\$192.168.16.20\t$current_name" /etc/hosts
        sed -i "/addresses: \[$current_ip\]/c\      addresses: [$192.168.16.20]" /etc/netplan/01-netcfg.yaml
        netplan apply
        log_changes "Changed IP address to '$192.168.16.20'"
    fi
}

# Function to configure host entry
configure_hostentry() {
    if ! grep -q "$myhost" /etc/hosts; then
        echo -e "$192.168.16.20\t$myhost" >> /etc/hosts
        log_changes "Added host entry: $myhost - $192.168.16.20"
    fi
}

# Main function
main() {
    case $setting in
        name )
            configure_name
            ;;
        ip )
            configure_ip
            ;;
        hostentry )
            configure_hostentry
            ;;
        * )
            display_error "Invalid option"
            ;;
    esac
}

# Call main function
main

