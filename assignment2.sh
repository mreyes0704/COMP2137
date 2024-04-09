#!/bin/bash
#1. Netlan System Modification
update_netplan_config() {
    cat <<EOF | sudo tee /etc/netplan/01-network-manager-all.yaml > /dev/null
network:
  version: 2
  ethernets:
      eth1:
      addresses: [192.168.16.21/24] 
      gateway4: 192.168.16.1 
           
EOF
}
# Update /etc/hosts File
update_hosts_file() {
    sudo sed -i '/192.168.16.21/d' /etc/hosts # Remove old entry
    echo "192.168.16.21   server1" | sudo tee -a /etc/hosts > /dev/null # Add new entry
}

# To apply netplan
apply_changes() {
    sudo netplan apply 
    sudo systemctl restart networking 
}

echo "Updating Netplan configuration..."
update_netplan_config
echo "Updating /etc/hosts file..."
update_hosts_file
echo "Applying changes..."
apply_changes
echo "Configuration completed."


>>>>>>> 8c44135 (This is a script for Linux configure-host.sh)

# 2. Apache and squid proxy app installation in defaualt configuration
# Install and update apache2
sudo apt update
sudo apt install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl stop apache2

# Revert Apache2 in default configuration
sudo cp /etc/apache2/apache2.conf.orig /etc/apache2/apache2.conf
sudo cp /etc/apache2/ports.conf.orig /etc/apache2/ports.conf

# Remove custom virtual host configurations
sudo rm -f /etc/apache2/sites-available/*.conf
sudo rm -f /etc/apache2/sites-enabled/*.conf

# Enable default virtual host
sudo ln -s /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-enabled/000-default.conf
sudo systemctl start apache2

# Check if Apache2 service is running
if systemctl is-active --quiet apache2; then
    echo "Apache2 is running."
  
    # Check if Apache2 configuration is default configuration
    if [ -f "/etc/apache2/apache2.conf" ]; then
        echo "Apache2 is using the default configuration."
    else
        echo "Apache2 is not using the default configuration."
    fi
else
    echo "Apache2 is not running."
fi

# Install and update Squid WebProxy
sudo apt update
sudo apt install -y squid
sudo systemctl start squid
sudo systemctl enable squid

# Check if Squid service is running
if systemctl is-active --quiet squid; then
    echo "Squid service is running."

    # Check if Squid is using the default configuration file
    if [ -f "/etc/squid/squid.conf" ]; then
        echo "Squid is using the default configuration file."

    else
        echo "Squid is not using the default configuration file."
    fi
else
    echo "Squid service is not running."
fi
# 3. Firewall Script configuration
# Enable ufw
sudo ufw enable

# Allow SSH on port 22 only on the management network
sudo ufw allow from mgmt_network_ip to any port 22

# Allow HTTP on both interfaces
sudo ufw allow http

# Allow web proxy on both interfaces (assuming default Squid proxy port 3128)
sudo ufw allow 3128
sudo ufw logging on

# Reload ufw to apply changes
sudo ufw reload

# Display firewall rules
sudo ufw status verbose

# 4. Create users

usernames=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

# Create users with home directory and bash shell
for user in "${usernames[@]}"; do
    sudo useradd -m -s /bin/bash "$user"
done

#Create SSH Keys for rsa and ed25519 algorithm
for username in "${usernames[@]}"; do
    # Check if the user exists
    if id "$username" &>/dev/null; then
        echo "SSH keys for $username is been added"

        # Create user's SSH directory if it doesn't exist
        sudo -u "$username" mkdir -p /home/"$username"/.ssh
	sudo chmod 700 "/home/${username}/.ssh"
        # Generate RSA key pair if it doesn't exist
        if [ ! -f "/home/$username/.ssh/id_rsa" ]; then
            sudo -i -u "$username" ssh-keygen -t rsa -N "" -f "/home/$username/.ssh/id_rsa"
        fi

        # Generate Ed25519 key pair if it doesn't exist
        if [ ! -f "/home/$username/.ssh/id_ed25519" ]; then
            sudo -i -u "$username" ssh-keygen -t ed25519 -N "" -f "/home/$username/.ssh/id_ed25519"
        fi

        # Append RSA public key to authorized_keys
        cat "/home/$username/.ssh/id_rsa.pub" | sudo -u "$username" tee -a "/home/$username/.ssh/authorized_keys" >/dev/null

        # Append Ed25519 public key to authorized_keys
        cat "/home/$username/.ssh/id_ed25519.pub" | sudo -u "$username" tee -a "/home/$username/.ssh/authorized_keys" >/dev/null
    else
        echo "User $username does not exist."
    fi
done

# Configure userid dennis to have sudo access

userid="dennis"

# Check if the user exists
if id "$userid" &>/dev/null; then
    # Add the user to the sudo group
    usermod -aG sudo "$userid"
    echo "Sudo access granted to $userid."
else
    echo "User $userid does not exist."
fi

# Define the public key
public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

# Check if the user exists
if ! id "$userid" &>/dev/null; then
    echo "User '$userid' does not exist."
    exit 1
fi

# Make the .ssh directory 
sudo mkdir -p /home/"$userid"/.ssh

# Set the correct permissions
sudo chmod 700 /home/"$userid"/.ssh

# Add the public key to the authorized_keys file
echo "$public_key" >> /home/"$userid"/.ssh/authorized_keys

# Set the correct permissions for the authorized_keys file
sudo chmod 600 /home/"$userid"/.ssh/authorized_keys

# Set the ownership of the .ssh directory and authorized_keys file
sudo chown -R "$userid:$userid" /home/"$userid"/.ssh

echo "SSH access has been configured for user '$userid'."
