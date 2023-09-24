#!/bin/bash

sudo apt-get update
sudo apt-get install -y openssl

VAULT_PASSWORD_PATH="$HOME/.config/dotfiles/vault_password.txt"
VAULT_PATH="vault.yml"

if [[ ! -f $VAULT_PASSWORD_PATH ]]; then
    # Creating the vault password file
    echo "[info] the file containing the ansible vault password is not present"
    echo "enter ansible vault password :"
    read ansible_vault_password

    mkdir -p "$HOME/.config/dotfiles"
    echo $ansible_vault_password > $VAULT_PASSWORD_PATH
    echo "[info] ansible Vault password stored in file '\$HOME/.config/dotfiles/vault_password.txt'"
fi

if [[ ! -f $VAULT_PATH ]]; then
    # Creating the vault
    echo "[info] the ansible vault is not present"

    # Add vault entries
    # - git_username
    echo "enter your git username:"
    read git_username
    ansible-vault encrypt_string --vault-password-file $VAULT_PASSWORD_PATH --name 'git_username' $git_username >> $VAULT_PATH
    # - git_email
    echo "" >> $VAULT_PATH
    echo "enter your git email:"
    read git_email
    ansible-vault encrypt_string --vault-password-file $VAULT_PASSWORD_PATH --name 'git_email' $git_email >> $VAULT_PATH

    echo "[info] encrypting the vault"
    ansible-vault encrypt vault.yml --vault-password-file $VAULT_PASSWORD_PATH
else
    echo "[info] the ansible vault is already present"
fi

exit 0