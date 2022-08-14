---
export ANSIBLE_LIBRARY=/mnt/c/Users/Public/Dev/Admin-sys/dotfiles/library/
ansible -m github_release.py -a 'repo_name=bottom repo_owner=ClementTsang asset_name=amd64.deb' localhost
ansible -m github_release.py -a 'repo_name=neovim repo_owner=neovim asset_name=nvim-linux64.deb' localhost
python3 github_release.py github_release_args.json 
---

---
export ANSIBLE_LIBRARY=/mnt/c/Users/Public/Dev/Admin-sys/dotfiles/library/
ansible -m get_vscode_path.py localhost
python3 github_release.py github_release_args.json 
---