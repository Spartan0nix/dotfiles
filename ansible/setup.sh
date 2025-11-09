#!/bin/bash

# Function used to return the appropriate method to perform operations that require administrative privileges.
function get_become_function {
    local function=""

    # Running as root, no function needed
    if [[ $(id -u) -eq 0 ]]
    then
        function=""
    else
        # The user can use `sudo`
        if [[ 0 -eq $(groups | grep -q -E "(sudo|wheel)") ]]
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

    # Retrieve the id of the distribution.
    if [[ -f /etc/os-release ]]
    then
        source /etc/os-release
        if [[ -n $ID ]]
        then
            distro=$(echo $ID | tr "[:upper:]" "[:lower:]")
        fi
    else
        # Use 'lsb_release' if available.
        if command -v lsb_release &>/dev/null
        then
            distro=$( \
                lsb_release --id --short \
                | grep -v "No LSB modules are available" \
                | tr "[:upper:]" "[:lower:]" \
            )
        else
            echo "> Unable to determine the current distribution."
            exit 1
        fi
    fi

    echo $distro
}

# Wrapper used to handle installation based on the current distro.
function handle_setup {
    local distro=$1
    local become_function=$2

    case $distro in
        arch|Arch|endeavouros|EndeavourOS)
            echo "-- Setting up configurations for 'Arch'."
            setup_arch $become_function
            ;;
        debian|Debian)
            echo "-- Setting up configurations for 'Debian'."
            setup_debian $become_function
            ;;
        *)
            echo "-- Unsupported distribution '$distro'."
            exit 1
            ;;
    esac

    #echo "> Configuring the Python Virtual Environment..."
    #setup_venv
}

# Function used to detected missing pacakges from the system.
function get_missing_packages {
    local missing_packages=""

    # Check for missing OS level packages.
    for package in $(echo "$1")
    do
        # Extract the command and the package name.
        local package_cmd=$(echo $package | cut --delimiter ':' --field 1)
        local package_name=$(echo $package | cut --delimiter ':' --field 2)
        if ! command -v $package_cmd  &>/dev/null
        then
            missing_packages="$missing_packages $package_name"
        fi
    done

    echo $missing_packages
}

# Function used to setup the system (Arch).
function setup_arch {
    local become_function=$1

    echo "-- Checking requirements."

    # Format : <command>:<package_name>
    local required_packages="\
        python3:python \
        pip3:python-pip \
        git:git \
        wget:wget \
    "
    local missing_packages=$(get_missing_packages "$required_packages")

    # Install the missing packages.
    if [[ $missing_packages != "" ]]
    then
        echo "-- Installing the following missing requirements ($missing_packages)."
	    $become_function pacman -Sy --noconfirm $missing_packages 1>/dev/null
    else
        echo "-- All the basic requirements have been met."
    fi

}

# Function used to setup the system (Debian).
function setup_debian {
    local become_function=$1
    export DEBIAN_FRONTEND=noninteractive

    # ------------------ #
    #       System       #
    # ------------------ #
    echo "-- Checking requirements."

    local required_packages="\
        python3:python3 \
        pip3:python3-pip \
        pip3:python3-venv \
        git:git \
        wget:wget \
    "
    local missing_packages=$(get_missing_packages "$required_packages")

    if [[ $missing_packages != "" ]]
    then
        echo "-- Installing the following missing requirements ($missing_packages)"
	    $become_function apt-get update 1>/dev/null
	    $become_function apt-get install --no-install-recommends -y $missing_packages 1>/dev/null
    else
        echo "-- All the basic requirements have been met."
    fi
}

# Function used to setup the Python Virtual Environment.
function setup_venv {
    # Create the local venv
    echo "-- Creating the venv."
    python3 -m venv .venv
    echo "-- Activating the venv."
    source .venv/bin/activate

    echo "-- Installing Python requirements."
    pip install -r requirements.txt --upgrade 1>/dev/null
}

# --------------
# -- Settings --
# --------------
# Exit on error
set -e

# ----------
# -- Main --
# ----------
echo "> Detecting the method to use for privileged actions."
become_function=$(get_become_function)
echo "-- Using: '$become_function'"

echo "> Retrieving information about the current distribution."
os_distro=$(get_currrent_distro)

echo "> Handling the installation based on the distribution."
handle_setup $os_distro $become_function

echo "> Setting up the Python Virtual Environment."
setup_venv

echo "> Installing the Ansible Galaxy requirements."
ansible-galaxy collection install --requirements-file requirements.yml --upgrade 1>/dev/null

echo "> Dotfiles requirements have been set up."
echo "> Next, execute the following commands."
echo "-- $ source .venv/bin/activate"
echo "-- $ make run"

exit 0
