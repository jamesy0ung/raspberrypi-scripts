#!/bin/bash
sudo apt-get install python3-pip python3-venv i2c-tools libgpiod-dev python3-libgpiod python3-smbus -y
sudo apt install --upgrade python3-setuptools -y
cd ~
python3 -m venv env --system-site-packages
source env/bin/activate
echo "source env/bin/activate" >> ~/.bashrc
pip3 install --upgrade adafruit-python-shell
wget https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/raspi-blinka.py
sudo -E env PATH=$PATH python3 raspi-blinka.py
pip3 install --upgrade RPi.GPIO adafruit-blinka
