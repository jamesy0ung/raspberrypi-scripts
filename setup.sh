#!/bin/bash
mkdir -p ~/.ssh
if curl -s https://github.com/jamesy0ung.keys >> ~/.ssh/authorized_keys; then
    echo "SSH key added successfully."
    sudo sed -i 's/^#*\(PasswordAuthentication\s*\).*$/\1no/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*\(ChallengeResponseAuthentication\s*\).*$/\1no/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*\(PubkeyAuthentication\s*\).*$/\1yes/' /etc/ssh/sshd_config
    echo "SSH password authentication disabled."
else
    echo "Failed to add SSH key. SSH password authentication not changed."
fi

echo "dtoverlay=sdtweak,overclock_50=100" | sudo tee -a /boot/firmware/config.txt
sudo sed -i 's/^#\(dtparam=i2c_arm=on\)/\1/' /boot/config.txt
sudo sed -i 's/^#\(dtparam=spi=on\)/\1/' /boot/config.txt

sudo apt update
sudo apt upgrade -y
sudo apt-get install --no-install-recommends -y \
    vim \
    cmake \
    libusb-1.0-0-dev \
    rtl-sdr \
    python3-pip \
    python3-venv \
    i2c-tools \
    libgpiod-dev \
    python3-libgpiod \
    python3-smbus \
    git \
    build-essential \
    aircrack-ng \
    firmware-linux-nonfree \
    firmware-ralink \
    firmware-realtek \
    raspberrypi-kernel-headers \
    libgmp3-dev \
    gawk \
    bison \
    flex \
    make \
    autoconf \
    libtool \
    texinfo \
    python3-dev \
    python3 \
    python3-setuptools
sudo apt purge modemmanager -y
sudo apt apt autoremove --purge
sudo apt clean
sudo apt install --upgrade python3-setuptools -y
sudo wget https://github.com/jamesy0ung/raspberrypi-scripts/raw/master/rtl8188fufw.bin -O /lib/firmware/rtlwifi/rtl8188fufw.bin
cd ~
git clone https://github.com/F5OEO/rpitx
python3 -m venv env --system-site-packages
source env/bin/activate
echo "source ~/env/bin/activate" >> ~/.bashrc
pip3 install --upgrade adafruit-python-shell RPi.GPIO adafruit-blinka
