# dotfiles

## Requirements

- `git`
- `make`
- `yay` (Archlinux)

## Installation

- Retrieve the sources.

```bash
mkdir -p ~/.config/
cd ~/.config/
git clone https://github.com/Spartan0nix/dotfiles.git
cd dotfiles/ansible
```

- Setup requirements

```bash
make setup
```

- Configure the `group_vars/all/main.yml` file base on the sample `group_vars/all/main.yml.sample`.

> This file is not versionned allowing for local overwrite.

- Execute the playbook

```bash
source .venv/bin/activate
make run
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

## Known issues

### No version information available (required by git)

> git: /usr/lib/libpcre2-8.so.0: no version information available (required by git)

- Archlinux

To fix this issue on Archlinux, reinstall the `pcre2` package using `pacman`.

```bash
sudo pacman -Sy pcre2
```
