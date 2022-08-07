#!/bin/sh

if [ ! -f $HOME/.ssh/id_git ]; then
    echo "Private ssh key '\$HOME/.ssh/id_git' already exist"
    echo "Would you like to generate a new pair of keys ? (Y|N)"
    read overwrite_ssh_keys

    valid_input="^(y$|Y$|yes$)"
    if [ $overwrite_ssh_keys =~ $valid_input ]; then
        echo "Generating SSH key for Git"
        ssh-keygen -q -t ed25519 -C "${git_email}" -N '' -f $HOME/.ssh/id_git
    fi
else
    echo "Generating SSH key for Git"
    ssh-keygen -q -t ed25519 -C "${git_email}" -N '' -f $HOME/.ssh/id_git
fi

# Starting ssh agent
eval "$(ssh-agent -s)"

# Adding the ssh key
ssh-add ~/.ssh/id_git