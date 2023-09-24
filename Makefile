genkey:
	ssh-keygen -t ed25519 -f ~/.ssh/id_ansible_dotfiles
	eval "$$(ssh-agent -s)"
	# Next use
	# ssh-copy-id -i ~/.ssh/id_ansible_dotfiles username@remote_host

ping:
	ansible --private-key ~/.ssh/id_ansible_dotfiles -m ping -i inventory.yml localhost

ping-remote:
	ansible --private-key ~/.ssh/id_ansible_dotfiles -m ping -i inventory.yml remotemachines

facts:
	ansible --private-key ~/.ssh/id_ansible_dotfiles -m setup -i inventory.yml localhost

facts-remote:
	ansible --private-key ~/.ssh/id_ansible_dotfiles -m setup -i inventory.yml remotemachines

lint:
	ansible-lint main.yml

vault:
	/bin/bash scripts/vault.sh

install-local-requirements:
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get install -y ansible ansible-lint

run:
	ansible-playbook --private-key ~/.ssh/id_ansible_dotfiles \
		--ask-become-pass \
        --vault-password-file $$HOME/.config/dotfiles/vault_password.txt \
        -e @vault.yml \
        main.yml

run-debug:
	ansible-playbook --private-key ~/.ssh/id_ansible_dotfiles \
		--ask-become-pass \
        --vault-password-file $$HOME/.config/dotfiles/vault_password.txt \
        -e @vault.yml \
		-vvv \
        main.yml

install:
	/bin/bash main.sh