#!/bin/bash

# Remove default system bell sound
echo "Disabling bell notification"
sudo sed -i 's/# set bell-style none/set bell-style none/' /etc/inputrc

# Upgrade the system
echo "Upgrading the system"
sudo apt update
sudo apt upgrade -y

# Install ansible
echo "Installing ansible"
sudo apt install ansible -y

# Update community general module
echo "Installing ansible galaxy collection"
ansible-galaxy collection install community.general

# Check if the ansible vault exist
if [[ ! -f vault.yml  ]]; then
    bash scripts/vault.sh
fi

VAULT_PASSWORD_PATH=$HOME/.config/dotfiles/vault_password.txt
if [[ -f $VAULT_PASSWORD_PATH ]]; then
    # Run ansible playbook
    ansible-playbook main.yml --ask-become-pass --vault-password-file $VAULT_PASSWORD_PATH --inventory localhost,
else
    # Run ansible playbook
    ansible-playbook main.yml --ask-become-pass --ask-vault-password --inventory localhost,
fi
