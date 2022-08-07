#!/usr/bin/env sh

# Remove default system bell sound
sudo sed -i 's/# set bell-style none/set bell-style none/' /etc/inputrc

# Upgrade the system
sudo apt update && sudo apt upgrade -y

# Install ansible
sudo apt install ansible -y

# Update community general module
ansible-galaxy collection install community.general

# Check if the ansible vault exist
if [ ! -f vault.yml  ]; then
    sh scripts/vault.sh
fi

VAULT_PASSWORD_PATH=$HOME/.config/dotfiles/vault_password.txt
if [ -f $VAULT_PASSWORD_PATH ]; then
    # Run ansible playbook
    ansible-playbook main.yml --ask-become-pass --vault-password-file $VAULT_PASSWORD_PATH -e "@vault.yml"
else
    # Run ansible playbook
    ansible-playbook main.yml --ask-become-pass --ask-vault-password -e "@vault.yml"
fi
