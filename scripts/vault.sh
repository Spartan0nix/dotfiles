#!/bin/bash

sudo apt update
sudo apt install -y openssl

VAULT_PASSWORD_PATH=$HOME/.config/dotfiles/vault_password.txt
VAULT_PATH="vault.yml"

if [[ ! -f $VAULT_PASSWORD_PATH ]]; then
    # Creating the vault password file
    echo "The file containing the ansible vault password is not present."
    echo "Enter ansible vault password :"
    read ansible_vault_password

    mkdir -p $HOME/.config/dotfiles
    echo $ansible_vault_password > $VAULT_PASSWORD_PATH
    echo "Ansible Vault password stored in file '\$HOME/.config/dotfiles/vault_password.txt'"
fi

if [[ ! -f $VAULT_PATH ]]; then
    # Creating the vault
    echo "The ansible vault is not present."
    ansible-vault create $VAULT_PATH --vault-password-file $VAULT_PASSWORD_PATH
    echo "Ansible vault '${VAULT}' created"

    # Add vault entries
    echo "Decrypting vault"
    ansible-vault decrypt vault.yml --vault-password-file $VAULT_PASSWORD_PATH

    echo "Adding values to the vault"

    # Add git_username
    echo "Enter git username :"
    read git_username
    ansible-vault encrypt_string $git_username --name "git_username" --vault-password-file $VAULT_PASSWORD_PATH >> $VAULT_PATH

    # Add git_email
    echo "Enter git email :"
    read git_email
    ansible-vault encrypt_string $git_email --name "git_email" --vault-password-file $VAULT_PASSWORD_PATH >> $VAULT_PATH

    echo "Encrypting vault"
    ansible-vault encrypt vault.yml --vault-password-file $VAULT_PASSWORD_PATH
else
    echo "The ansible vault is already present. Skipping ..."
fi

exit 0