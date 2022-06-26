# ~/.zshrc file for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

# Disable all beep/bell sounds
unsetopt BEEP

setopt interactivecomments # allow comments in interactive mode
setopt numericglobsort
setopt promptsubst

# hide EOL sign ('%')
PROMPT_EOL_MARK=""

# Keybindings configurations
bindkey -e                                        # emacs key bindings

# Completion configurations
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it

# zplug - manage plugins
source /usr/share/zplug/init.zsh
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/sudo", from:oh-my-zsh
zplug "plugins/command-not-found", from:oh-my-zsh
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zsh-completions"
zplug "junegunn/fzf"
# Theme
eval "$(starship init zsh)"

# zplug - install/load new plugins when zsh is started or reloaded
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load --verbose

# Clear the PATH if running WSL
# ZSH performance can decrease a lot due to heavy number of entries in the PATH
if [[ -d /mnt/wsl ]]; then
        export PATH=/usr/share/zplug/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib
fi