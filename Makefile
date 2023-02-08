genkey:
	ssh-keygen -t ed25519 -f ~/.ssh/id_ansible_dotfiles
	eval "$$(ssh-agent -s)"
	# Next use
	# ssh-copy-id -i ~/.ssh/id_ansible_dotfiles username@remote_host

list-inventory:
	ansible-inventory -i inventory.test.yml --list

ping:
	ansible --private-key ~/.ssh/id_ansible_dotfiles targetmachines -m ping -i inventory.test.yml

lint:
	ansible-lint main.yml

run:
	ansible-playbook --private-key ~/.ssh/id_ansible_dotfiles --ask-become-pass -i inventory.test.yml main.yml