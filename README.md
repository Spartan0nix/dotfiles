# dotfiles

## Installation

### (optional) - Setup custom CA for WSL

Download the script 'wsl-configure-ca.ps1' from the UI or using the following command :

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri https://githubraw.com/Spartan0nix/dotfiles/main/scripts/wsl-configure-ca.ps1 -OutFile wsl-configure-ca.ps1; ./wsl-configure-ca.ps1; Remove-Item wsl-configure-ca.ps1"
```

### Install

```bash
git clone https://github.com/Spartan0nix/dotfiles.git
cd dotfiles
```

Before executing the **install.sh** script, update the **hosts** (*targetmachines*) field from **main.yml** to **localhost**.

Then :
```
bash install.sh
```

## Post install

### Shell
Close the existing session and start a new one. It should open a ZSH shell.

### Neovim
Open Neovim with the command **nvim** .

You should see a lot of error since the configuration file is trying to use non present plugins, present **q** to close the error tab.

Inside Neovim window, install the different plugins with the following commands :

```
:PlugInstall
:q
```

> <u>***Note :***</u> Some plugins while fail their post-hook command (TSUpdate for exemple).

Start a new Neovim session to make sure everything is reloaded and executing the following commands :

```
:TSUpdate
:q
```