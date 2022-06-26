#!/usr/bin/env sh

# Remove default system bell sound
sudo sed -i 's/# set bell-style none/set bell-style none/' /etc/inputrc

# Upgrade the system
sudo apt update && sudo apt upgrade -y

# Install ansible
sudo apt install ansible -y

# Upgrade pip3
# sudo -H pip3 install --upgrade pip

# ansible-playbook main.yml --ask-become-pass