#!/bin/bash

echo "Run from the playbook directory not the library directory !!"

export ANSIBLE_LIBRARY="$(pwd)/library"

# Test with Bottom
ansible -m "github_release" -a 'repo_name=bottom repo_owner=ClementTsang asset_name=amd64.deb' localhost

# Test with Neovim
ansible -m "github_release" -a 'repo_name=neovim repo_owner=neovim asset_name=nvim-linux64.deb' localhost

# Run as a python script and not an ansible module
python3 github_release.py github_release_args.json 