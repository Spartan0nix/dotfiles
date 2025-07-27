SHELL = /bin/bash

run-wsl:
	ansible-playbook \
		--inventory=./inventory.yml \
		--ask-become-pass \
		wsl.yml

run-standalone:
	ansible-playbook \
		--inventory=./inventory.yml \
		--ask-pass \
		--ask-become-pass \
		standalone.yml
