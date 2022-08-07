# ~/.zshrc file for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export ZSH_THEME="robbyrussell"

# Disable all beep/bell sounds
unsetopt BEEP

# hide EOL sign ('%')
PROMPT_EOL_MARK=""

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    sudo
    command-not-found
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-history-substring-search
    zsh-completions
)

source $ZSH/oh-my-zsh.sh

# Convert a Windows PATH to a linux PATH before executin 'cd'
function cdw() {
    if [ $# -eq 1 ]; then
        converted_path=$(print -P '%{$1%}' | sed 's/C\:/c/' | sed 's/\\/\//g')
        cd_target="/mnt/${converted_path}"
        cd $cd_target
    else
        echo "Missing required Windows path"
    fi
    unset converted_path
    unset cd_target
}

# Clear the PATH if running WSL
# ZSH performance can decrease a lot due to heavy number of entries in the PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib
