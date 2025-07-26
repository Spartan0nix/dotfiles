# dotfiles

## Installation

```bash
curl https://raw.githubusercontent.com/Spartan0nix/dotfiles/main/main.sh | /bin/bash -
```

## Post install

### Shell

Close the existing session and start a new one. It should open a ZSH shell.

## Common shell configuration

All configurations regarding PATH update, environment variable settings, etc. are done in a `$HOME/.config/shell/common.sh`.

Do not forget to source this file in your `.bashrc` or `.zshrc`.

```bash
$HOME/.bashrc
---
[...]
if [[ -f ~/.config/shell/common.sh ]]
then
    source ~/.config/shell/common.sh
fi
[...]
```

> This step is already taken care for ZSH if the shell was configured using the provided `zsh` ansible role.
