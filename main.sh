#!/bin/bash

# Branch or Tag of the 'dotfiles' Git repository.
DOTFILES_GIT_REPO_BRANCH="main"

# Function used to cleanup sources before exiting when an error occures.
function cleanup {
    echo "> Cleaning up before exiting..."
    if [[ -d "$HOME/.ansible-dotfiles" ]]
    then
        rm -fr "$HOME/.ansible-dotfiles"
    fi
}

# Function used to return the appropriate method to perform operations that require administrative privileges.
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

# Function used to extract the current distribution.
function get_currrent_distro {
    local distro=""

    if [[ -f /etc/os-release ]]
    then
        distro=$(cat /etc/os-release | grep "^ID" | sed 's/ID=//')
    else
        if command -v lsb_release &>/dev/null
        then
            distro=$( \
                lsb_release --id --short \
                | grep -v "No LSB modules are available" \
                | tr "[:upper:]" "[:lower:]" \
            )
        else
            echo "> Unable to determine the current distribution, aborting..."
            exit 1
        fi
    fi

    echo $distro
}

# Wrapper used to handle installation based on the current distro.
function handle_setup {
    local distro=$1
    local become_function=$2

    if [[ $distro == "debian" ]]
    then
        echo "> Setting up configurations for 'debian'..."
        setup_debian $become_function
    else
        echo "> Unsupported distribution '$distro'"
        exit 1
    fi
}

# Function used to setup the system (Debian).
function setup_debian {
    local become_function=$1

    echo "> Checking requirements..."

    # Check for missing OS level packages.
    local missing_packages=""
    if ! command -v python3 &>/dev/null; then local missing_packages="$missing_packages python3"; fi
    if ! command -v pip3 &>/dev/null; then local missing_packages="$missing_packages python3-pip"; fi
    if ! command -v git &>/dev/null; then local missing_packages="$missing_packages git"; fi
    if ! command -v wget &>/dev/null; then local missing_packages="$missing_packages wget"; fi

    if [[ $missing_packages != "" ]]
    then
        echo "  - Installing missing requirements... ($missing_packages)"
	    $become_function apt-get update 1>/dev/null
	    $become_function apt-get install -y $missing_packages 1>/dev/null
    else
        echo "  - All the basic requirements have been met"
    fi

    # The 'EXTERNALLY-MANAGED' file prevents users from installing Python modules directly using `pip`.
    # Instead, users need to install modules using the system package manager (in this case, `apt`).
    # These packages are usually out of date :). We will remove the file so that we can install modules using `pip`.
	local python_version=$(python3 --version | sed 's/Python //' | cut --delimiter="." --fields="1,2")
	if [[ -f "/usr/lib/python$python_version/EXTERNALLY-MANAGED" ]]
	then
	    echo "  - Removing the 'EXTERNALLY-MANAGED' flag from '/usr/lib/python$python_version/'..."
        $become_function rm "/usr/lib/python$python_version/EXTERNALLY-MANAGED"
    else
        echo "  - 'python' is already configured"
    fi

    # Install the Ansible CLI + update the PATH.
    if ! command -v ansible-playbook &>/dev/null
    then
        echo "  - Installing 'ansible' using pip..."
        pip install ansible
        if [[ $(grep "export PATH=\$PATH:\$HOME/.local/bin" ~/.bashrc) == "" ]]
        then
            echo "- Adding '$HOME/.local/bin' to the PATH in '~/.bashrc'..."
            echo -e "\nexport PATH=\$PATH:\$HOME/.local/bin" >> "$HOME/.bashrc"
	        source "$HOME/.bashrc"
        fi
    else
        echo "  - 'ansible' is already installed"
    fi

    # Retrieve a version of the Gum CLI.
    gum_latest_version=$(git ls-remote --tags https://github.com/charmbracelet/gum.git \
        | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+$' \
        | cut --delimiter="/" --fields=3 \
        | sort --version-sort \
        | tail -1 \
        | sed 's/^v//' \
    )

    # Retrieve the current version.
    gum_current_version=$(dpkg -s gum 2>/dev/null | grep '^Version:' | sed 's/Version: //')
    if [[ $gum_latest_version != $gum_current_version ]]
    then
        echo "  - Installing the latest version of 'gum'... ($gum_latest_version)"
        wget --quiet "https://github.com/charmbracelet/gum/releases/download/v${gum_latest_version}/gum_${gum_latest_version}_amd64.deb"
        $become_function dpkg -i "gum_${gum_latest_version}_amd64.deb" 1>/dev/null
        rm "gum_${gum_latest_version}_amd64.deb"
    else
        echo "  - 'gum' is already installed"
    fi
}

# Function used to select the ansible tags.
function select_tags {
    local selected_tags=$(\
        gum choose \
            --no-limit \
                "all" \
                "ansible_dev" \
                "docker" \
                "gcloud" \
                "git" \
                "go" \
                "helm" \
                "jq" \
                "k9s" \
                "kubectl" \
                "nodejs" \
                "opentofu" \
                "python" \
                "terraform" \
                "trivy" \
                "vscode" \
                "yq" \
                "zsh"\
    )

    # Overwrite the tags list if 'all' is set.
    if [[ $selected_tags == *"all"* ]]
    then
        selected_tags="all"
    fi

    echo $selected_tags
}

# --------------
# -- Settings --
# --------------
# Exit on error
set -e
trap cleanup ERR

# ---------------
# -- Constants --
# ---------------
# Directory used to clone the Git repository.
GIT_DESTINATION_FOLDER="$HOME/.ansible-dotfiles"

# ----------
# -- Main --
# ----------
echo "> Detecting the method to use for privileged actions..."
become_function=$(get_become_function)
echo "  - Using: '$become_function'"

echo "> Retrieving information about the current distribution..."
os_distro=$(get_currrent_distro)

echo "> Handling the installation based on the distribution..."
handle_setup $os_distro $become_function

# --
# Can be disable when developing locally.
# --
echo "> Cloning the Git repository in '$GIT_DESTINATION_FOLDER'..."
overwrite_git_repo="yes"
if [[ -d $GIT_DESTINATION_FOLDER ]]
then
    echo "- The repository already exists on the machine, would you like to overwrite it ?"
    overwrite_git_repo=$(gum choose "yes" "no")
fi

if [[ $overwrite_git_repo == "yes" ]]
then
    echo "- Cloning the repository..."
    rm -rf $GIT_DESTINATION_FOLDER
    mkdir -p $GIT_DESTINATION_FOLDER
    git clone \
        --quiet \
        --branch $DOTFILES_GIT_REPO_BRANCH \
        --single-branch \
        "https://github.com/Spartan0nix/dotfiles.git" \
        "$GIT_DESTINATION_FOLDER"
fi

cd $GIT_DESTINATION_FOLDER
# --

echo "> Installing the Ansible Galaxy requirements..."
ansible-galaxy collection install --requirements-file ansible/requirements.yml --upgrade 1>/dev/null

echo "> Selecting the components to deploy..."
tags=$(select_tags)

echo "> Running the playbook..."
ansible-playbook --tags $tags ansible/main.yml

# --
# Can be disable when developing locally.
# --
cd $HOME
# --

cleanup
exit 0
