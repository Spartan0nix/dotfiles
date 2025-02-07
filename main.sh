#!/bin/bash

# Function used to cleanup sources before exiting when an error occures
function cleanup {
    echo "[info] cleaning up before exiting"
    if [[ -d "$HOME/.ansible-dotfiles" ]]
    then
        rm -fr "$HOME/.ansible-dotfiles"
    fi
}

# Function used to return the appropriate method to perform operations that require administrative privileges
function get_become_function {
    local function=""
    
    # Running as root, no function needed
    if [[ $(id -u) -eq 0 ]]
    then
        function=""
    else
        # The user can use `sudo`
        if [[ 0 -eq $(groups | grep -q "sudo") ]]
        then
            function="sudo"
        # Default use case, the user will take the identity of `root` using `su`
        else
            function="su -l -s /bin/bash root --"
        fi
    fi

    echo $function
}

# Function used to extract the current distribution
function get_currrent_distro {
    local distro=""

    if [[ -f /etc/os-release ]]
    then
        distro=$(cat /etc/os-release | grep "^ID" | sed 's/ID=//')
    else
        if command -v lsb_release &>/dev/null
        then
            distro=$(lsb_release --id --short \
            | grep -v "No LSB modules are available" \
            | tr "[:upper:]" "[:lower:]")
        else
            echo "[error] unable to determine the current distribution, aborting..."
            exit 1
        fi
    fi

    echo $distro
}

# Wrapper used to handle installation based on the current distro
function handle_setup {
    local distro=$1
    local become_function=$2

    if [[ $distro == "debian" ]]
    then
        setup_debian $become_function
    else
        echo "[error] unsupported distribution '$distro'"
        exit 1
    fi
}

# Function used to setup the system (Debian)
function setup_debian {
    local become_function=$1

    echo "[info] checking requirements"

    local missing_packages=""
    if ! command -v python3 &>/dev/null; then local missing_packages="$missing_packages python3"; fi
    if ! command -v pip3 &>/dev/null; then local missing_packages="$missing_packages python3-pip"; fi
    if ! command -v git &>/dev/null; then local missing_packages="$missing_packages git"; fi

    if [[ $missing_packages != "" ]]
    then
        echo "[warning] installing missing requirements ($missing_packages)"
	    $become_function apt-get update 1>/dev/null
	    $become_function apt-get install -y $missing_packages 1>/dev/null
    fi

	local python_version=$(python3 --version | sed 's/Python //' | cut --delimiter="." --fields="1,2")
	if [[ -f "/usr/lib/python$python_version/EXTERNALLY-MANAGED" ]]
	then
	    echo "[info] removing the 'EXTERNALLY-MANAGED' flag from '/usr/lib/python$python_version/'"
        $become_function rm "/usr/lib/python$python_version/EXTERNALLY-MANAGED"
    fi

    if ! command -v ansible-playbook &>/dev/null
    then
        echo "[warning] installing 'ansible' using pip"
        pip install ansible
        if [[ $(grep "export PATH=\$PATH:\$HOME/.local/bin" ~/.bashrc) == "" ]]
        then
            echo "[info] adding '$HOME/.local/bin' to the PATH in '~/.bashrc'"
            echo -e "\nexport PATH=\$PATH:\$HOME/.local/bin" >> "$HOME/.bashrc"
	        source "$HOME/.bashrc"
        fi
    fi
}

# Function used to select the ansible tags
function select_tags() {
    local available_tags=("all" "ansible_dev" "docker" "gcloud" "git" "go" "helm" "jq" "k9s" "kubectl" "nodejs" "opentofu" "python" "terraform" "trivy" "vscode" "yq" "zsh")

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


# Exit on error
set -e
trap cleanup ERR

become_function=$(get_become_function)
echo "[info] the following function will be used for actions that require elevated privileges: '$become_function'"

echo "[info] disabling system bell notification"
$become_function sed -i 's/# set bell-style none/set bell-style none/' /etc/inputrc

echo "[info] retrieving information about the current distribution"
os_distro=$(get_currrent_distro)

echo "[info] handling installation based on the distribution"
handle_setup $os_distro $become_function

# echo "[info] cloning the Git repository in '~/.ansible-dotfiles'"
# mkdir "$HOME/.ansible-dotfiles"
# git clone --quiet https://github.com/Spartan0nix/dotfiles.git "$HOME/.ansible-dotfiles"
# cd "$HOME/.ansible-dotfiles"

echo "[info] installing the required ansible galaxy collections"
ansible-galaxy collection install --requirements-file ansible/requirements.yml 1>/dev/null

echo "[info] selecting the components to deploy"
tags=$(select_tags)

echo "[info] running the playbook"
ansible-playbook --tags $tags ansible/main.yml

cd $HOME
cleanup

exit 0
