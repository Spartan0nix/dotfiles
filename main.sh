#!/bin/bash

# Exit on error
set -e

# Function used to cleanup sources before exiting when an error occures
function cleanup() {
    echo -e "[info] cleaning up before exiting"
    if [[ -d "$HOME/.ansible-dotfiles" ]]
    then
        rm -r "$HOME/.ansible-dotfiles"
    fi
}

# Function used to setup the system (Debian)
function setup_debian() {
    echo -e "\n[info] upgrading the system"
    sudo apt-get update
    sudo apt-get upgrade -y

    echo -e "\n[info] installing requirements"
    sudo apt-get install -y ansible git
}

# Cleanup on error
trap cleanup ERR

echo -e "\n[info] disabling bell notification"
sudo sed -i 's/# set bell-style none/set bell-style none/' /etc/inputrc

os_release=$(cat /etc/os-release | grep "^ID" | sed 's/ID=//')
if [[ $os_release == "debian" ]]
then
    echo -e "\n[info] current distribution identified as 'debian'"
    setup_debian
else
    echo -e "\n[error] unsupported distribution '$os_release'"
    echo "[info] supported distributions: 'debian'"
    exit 1
fi

echo -e "\n[info] cloning the Git repository"
mkdir "$HOME/.ansible-dotfiles"
git clone https://github.com/Spartan0nix/dotfiles.git "$HOME/.ansible-dotfiles"
cd "$HOME/.ansible-dotfiles"

echo "[info] installing ansible galaxy collections"
ansible-galaxy collection install -r ansible/requirements.yml

echo "[info] running the playbook"
ansible-playbook --ask-become-pass ansible/main.yml

cd $HOME

cleanup()

exit 0
