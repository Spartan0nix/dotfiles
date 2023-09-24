#!/bin/bash

# Remove default system bell sound
echo "[info] disabling bell notification"
sudo sed -i 's/# set bell-style none/set bell-style none/' /etc/inputrc

# Upgrade the system
echo "[info] upgrading the system"
sudo apt-get update
sudo apt-get upgrade -y

# Install ansible
echo "[info] installing ansible"
sudo apt-get install -y ansible

# Update community general module
echo "[info] installing ansible galaxy collection"
ansible-galaxy collection install -r requirements.yml

# Check if the ansible vault exist
if [[ ! -f vault.yml  ]]; then
    bash scripts/vault.sh
fi

VAULT_PASSWORD_PATH=$HOME/.config/dotfiles/vault_password.txt
# Run ansible playbook
ansible-playbook --private-key ~/.ssh/id_ansible_dotfiles \
    --ask-become-pass \
    --vault-password-file $VAULT_PASSWORD_PATH \
    -e @vault.yml \
    main.yml

exit 0

