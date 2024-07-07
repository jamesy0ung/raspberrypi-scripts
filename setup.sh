#!/bin/bash

# Set up error logging
ERROR_LOG="/home/james/setup-errors.log"
exec 2> >(tee -a "$ERROR_LOG" >&2)

# Function to log errors
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$ERROR_LOG"
}

# Function to add a user if they don't exist
add_user_if_not_exists() {
    if ! id "james" &>/dev/null; then
        sudo adduser james || log_error "Failed to add user james"
        sudo usermod -a -G wheel,adm,systemd-journal james || log_error "Failed to set groups for user james"
        echo "User james added and groups set."
    else
        echo "User james already exists."
    fi
}

# Function to set up SSH for the user
setup_ssh() {
    local ssh_dir="/home/james/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"
    local ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/L+qS1ciw35k3X3i+dOss9My96+U/z9cUqH4RD1Zqg1xv1VRMrL8ijY3ptB0eJMNC8+ggXsuT3D9ghLA/iHW8ujnBWTXfwo5QK3VbvciismP2u+UfLTfwbtqikXNY8Sgp4fTtUqnUOHsQJtivbg/GXiecyUy1ZbMx9RNlrIz/cyRslJ9Iu48QineOMFvNmNSmD6DPt3KI1VfLZpRGLp0hcuOzmEK68qb5CzOBoeCdXEen0Lp43w71bFFLuW18hioeokbbhoQu0dSsL0rf1AA4IpxC/tV75Y6yRopp7kQO1WuGmudCJfMHyN341p4TW5R5Hw6Ez7mp1m4jSoUEycSxUYonLTB+T5e6ttWA5+qWRxtX1PCRE4aRDXOYfdpkdTabMdtVSBPWEJUi6Mm9Rg4J82W/CZNTeN//j5SJwx725XSf8B/Ldgvr5tA7FjKDQKp1P13X24pA1EGyd1uKzpaEc0GtU7yJXPqTmMYCloKs8cHn4j4zahW6cKAHrZqnU+xj07GF/aF6bF3FgSINHs1TcZ2MfqfCc8nX0REDawxAwow4Ck3kDzcpdLvxCfgAdRzjDdKWa7JDuQAFiKpCwpSWZLpaIQVS5Q/nLS7NokEVO4pzgbjhFjTz9tkpZtwlOygY1LjkABaJW3SVJbb+oBEZztAwNUfyTW5BtB2izi3v5Q== james@Windoze"

    sudo mkdir -p "$ssh_dir" || log_error "Failed to create SSH directory"
    
    # Check if the SSH key already exists in the authorized_keys file
    if ! sudo grep -q "$ssh_key" "$auth_keys" 2>/dev/null; then
        echo "$ssh_key" | sudo tee -a "$auth_keys" > /dev/null || log_error "Failed to add SSH key"
        echo "SSH key added to authorized_keys file."
    else
        echo "SSH key already exists in authorized_keys file."
    fi

    sudo chown -R james:james "$ssh_dir" || log_error "Failed to set ownership of SSH directory"
    sudo chmod 700 "$ssh_dir" || log_error "Failed to set permissions on SSH directory"
    sudo chmod 600 "$auth_keys" || log_error "Failed to set permissions on authorized_keys file"

    # Disable password authentication and enable public key authentication
    sudo sed -i 's/^#*\(PasswordAuthentication\s*\).*$/\1no/' /etc/ssh/sshd_config || log_error "Failed to disable password authentication"
    sudo sed -i 's/^#*\(ChallengeResponseAuthentication\s*\).*$/\1no/' /etc/ssh/sshd_config || log_error "Failed to disable challenge response authentication"
    sudo sed -i 's/^#*\(PubkeyAuthentication\s*\).*$/\1yes/' /etc/ssh/sshd_config || log_error "Failed to enable public key authentication"
    echo "SSH configuration updated"
}

# Function to configure Raspberry Pi specific settings
configure_raspberry_pi() {
    echo "dtoverlay=sdtweak,overclock_50=100" | sudo tee -a /boot/firmware/config.txt || log_error "Failed to add SD card overclock setting"
    sudo sed -i 's/^#\(dtparam=i2c_arm=on\)/\1/' /boot/firmware/config.txt || log_error "Failed to enable I2C"
    sudo sed -i 's/^#\(dtparam=spi=on\)/\1/' /boot/firmware/config.txt || log_error "Failed to enable SPI"
    echo "Raspberry Pi specific configurations applied."
}

# Function to install packages on Raspberry Pi OS
install_raspberry_pi_packages() {
    sudo apt update || log_error "Failed to update package lists"
    sudo apt upgrade -y || log_error "Failed to upgrade packages"
sudo apt-get install --no-install-recommends -y \
    vim cmake libusb-1.0-0-dev rtl-sdr python3-pip python3-venv i2c-tools \
    libgpiod-dev python3-libgpiod python3-smbus git build-essential aircrack-ng \
    firmware-linux-nonfree firmware-ralink firmware-realtek \
    raspberrypi-kernel-headers libgmp3-dev gawk bison flex make autoconf \
    libtool texinfo python3-dev python3 python3-setuptools \
    libtool libusb-1.0-0-dev librtlsdr-dev rtl-sdr build-essential cmake pkg-config || log_error "Failed to install Raspberry Pi packages"
    sudo apt purge modemmanager -y || log_error "Failed to remove modemmanager"
    sudo apt autoremove --purge -y || log_error "Failed to autoremove packages"
    sudo apt clean || log_error "Failed to clean package cache"
    echo "Raspberry Pi OS packages installed and system cleaned."
}

# Function to install packages on Red Hat-based systems
install_redhat_packages() {
    sudo dnf update -y || log_error "Failed to update system"
    sudo dnf install --nogpgcheck -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm || log_error "Failed to install EPEL repository"
    sudo dnf install --nogpgcheck -y https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm || log_error "Failed to install RPM Fusion repositories"
    echo "Red Hat repositories added and system updated."
}

# Function to install packages on Debian-based systems
install_debian_packages() {
    sudo apt update || log_error "Failed to update package lists"
    sudo apt upgrade -y || log_error "Failed to upgrade packages"
    sudo apt install -y curl vim git || log_error "Failed to install Debian packages"

    # Check for Broadcom BCM4331 device and take action if present
    if lspci | grep -i "02:00.0 Network controller: Broadcom Inc. and subsidiaries BCM4331 802.11a/b/g/n (rev 02)"; then
        echo "Broadcom BCM4331 detected."

        # Blacklist b43 driver
        echo 'blacklist b43' | sudo tee /etc/modprobe.d/blacklist-b43.conf

        # Install bcm proprietary driver
        sudo apt-get install -y linux-image-$(uname -r | sed 's,[^-]*-[^-]*-,,') linux-headers-$(uname -r | sed 's,[^-]*-[^-]*-,,') broadcom-sta-dkms

        # Blacklist b43 driver in kernel cmdline
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 b43.blacklist=yes"/' /etc/default/grub

        # Rebuild grub
        sudo update-grub
    fi
    echo "Debian packages installed and Broadcom BCM4331 handled."
}

# Function to check if running on Raspberry Pi OS
is_raspberry_pi_os() {
    if [ -f /etc/rpi-issue ]; then
        return 0  # True, it is Raspberry Pi OS
    else
        return 1  # False, it is not Raspberry Pi OS
    fi
}

# Main execution
add_user_if_not_exists
setup_ssh

# Detect OS and install packages accordingly
if is_raspberry_pi_os; then
    echo "Detected Raspberry Pi OS"
    configure_raspberry_pi
    install_raspberry_pi_packages

    # Additional Raspberry Pi specific setup
    sudo wget https://github.com/jamesy0ung/raspberrypi-scripts/raw/master/rtl8188fufw.bin -O /lib/firmware/rtlwifi/rtl8188fufw.bin || log_error "Failed to download rtl8188fufw.bin"
    cd ~ || log_error "Failed to change to home directory"
    git clone https://github.com/F5OEO/rpitx || log_error "Failed to clone rpitx repository"
    python3 -m venv env --system-site-packages || log_error "Failed to create Python virtual environment"
    source env/bin/activate || log_error "Failed to activate Python virtual environment"
    echo "export VIRTUAL_ENV_DISABLE_PROMPT=1" >> ~/.bashrc || log_error "Failed to disable virtual environment prompt disabler to .bashrc"
    echo "source ~/env/bin/activate" >> ~/.bashrc || log_error "Failed to add virtual environment activation to .bashrc"
    pip3 install --upgrade adafruit-python-shell RPi.GPIO adafruit-blinka || log_error "Failed to install Python packages"
elif [ -f /etc/redhat-release ]; then
    echo "Detected Red Hat-based system"
    install_redhat_packages
elif [ -f /etc/debian_version ]; then
    echo "Detected Debian-based system"
    install_debian_packages
else
    log_error "Unsupported operating system"
    exit 1
fi

echo "Setup completed successfully!"
