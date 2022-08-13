---
export ANSIBLE_LIBRARY=/mnt/c/Users/Public/Dev/Admin-sys/dotfiles/library/
ansible -m github_release.py -a 'repo_name=tfsec repo_owner=aquasecurity asset_name=tfsec-linux-amd64' localhost
python3 github_release.py github_release_args.json 
---

---
export ANSIBLE_LIBRARY=/mnt/c/Users/Public/Dev/Admin-sys/dotfiles/library/
ansible -m get_vscode_path.py -a 'user=Leo' localhost
python3 github_release.py github_release_args.json 
---