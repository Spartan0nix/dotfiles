#!/bin/bash

# Exit on error
set -e

# Function used to cleanup sources before exiting when an error occures
function cleanup() {
    echo -e "[info] cleaning up before exiting"
    if [[ -d "$HOME/.ansible-dotfiles" ]]
    then
        rm -fr "$HOME/.ansible-dotfiles"
    fi
}

# Function used to setup the system (Debian)
function setup_debian() {
    echo -e "\n[info] checking requirements"

    local missing_packages=""
    if ! command -v python3 &>/dev/null; then local missing_packages="$missing_packages python3"; fi
    if ! command -v pip3 &>/dev/null; then local missing_packages="$missing_packages python3-pip"; fi
    if ! command -v git &>/dev/null; then local missing_packages="$missing_packages git"; fi

    if [[ $missing_packages != "" ]]
    then
        echo -e "\n[warning] installing missing requirements ($missing_packages)"
	sudo apt-get update
	sudo apt-get install $missing_packages

	local python_version=$(python3 --version | sed 's/Python //' | cut --delimiter="." --fields="1,2")
	if [[ -f "/usr/lib/python$python_version/EXTERNALLY-MANAGED" ]]
	then
	    echo "[info] removing the 'EXTERNALLY-MANAGED' flag from the python$python_version configuration directory"
            sudo rm "/usr/lib/python$python_version/EXTERNALLY-MANAGED" 
        fi
    fi

    if ! command -v ansible-playbook &>/dev/null
    then
        echo "[warning] installing 'ansible' using pip"
        pip install ansible
        if [[ $(grep "export PATH=\$PATH:\$HOME/.local/bin" ~/.bashrc) == "" ]]
        then
            echo "[info] adding '$HOME/.local/bin' to the PATH"
            echo -e "\nexport PATH=\$PATH:\$HOME/.local/bin" >> "$HOME/.bashrc"
	    source "$HOME/.bashrc"
        fi
    fi

}

# Function used to select the ansible tags
function select_tags() {
    local available_tags=("all" "zsh" "docker" "go" "bottom" "python" "git" "vscode" "nodejs" "terraform" "gcloud" "kubectl" "k9s" "helm")

    local menu_options=""
    for (( i=0; i < ${#available_tags[@]}; i++))
    do
        local menu_options="$menu_options $i ${available_tags[$i]} off"
    done

    local choices=$(whiptail \
        --separate-output \
        --checklist "Select components to deploy:" 22 35 14 \
        $menu_options \
        2>&1 \
        >/dev/tty)

    local tags=""
    local i=0
    for choice in $choices
    do
	if [[ "${available_tags[$choice]}" == "all" ]]
	then
	    local tags="all"
	    break
	else
	    if [[ $i -eq 0 ]]
	    then
		local tags="${available_tags[$choice]}"
		local i=$((i+1))
	    else
	        local tags="$tags,${available_tags[$choice]}"
	    fi
	fi
    done

    echo $tags
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

echo -e "\n[info] installing the required ansible galaxy collections"
$HOME/.local/bin/ansible-galaxy collection install -r ansible/requirements.yml

echo -e "\n[info] selection the components to deploy"
tags=$(select_tags)


echo -e "\n[info] running the playbook"
$HOME/.local/bin/ansible-playbook --tags $tags ansible/main.yml

cd $HOME

cleanup

exit 0
