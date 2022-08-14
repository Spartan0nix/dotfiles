#!/usr/bin/python

# Copyright: (c) 2022, Léo HUMBLOT <dev.humblole@gmail.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
__metaclass__ = type

DOCUMENTATION = r'''
---
module: get_vscode_path

short_description: Return the windows host path to vscode bin (code).

version_added: "1.0.0"

description: This module allow to return the path to the vscode bin (code) from the windows host when running WSL.

options:

extends_documentation_fragment:
    - local.dotfiles.get_vscode_path

author:
    - Léo HUMBLOT (@Spartan0nix)
'''

EXAMPLES = r'''
# Success
- name: Get vscode path
  local.dotfiles.get_vscode_path:
'''

RETURN = r'''
# Sample of possible returned values
found:
    description: Indicate if a path was found
    type: str
    returned: always
    sample: 'True'
original_path:
    description: The original windows path 
    type: str
    returned: always
    sample: 'C:\Users\john\AppData\Local\Programs\Microsoft VS Code\bin'
path:
    description: The path leading to the binary from withing WSL
    type: str
    returned: always
    sample: '/mnt/c/Users/john/AppData/Local/Programs/Microsoft\ VS\ Code/bin'
'''

from ansible.module_utils.basic import AnsibleModule
from subprocess import run
from re import search

def run_process(cmd):
    POWERSHELL_DEFAULT_PATH="/mnt/c/windows/system32/windowspowershell/v1.0/powershell.exe"
    res = run([POWERSHELL_DEFAULT_PATH, "-Command", cmd], capture_output=True)
    return res

def run_module():
    module_args = dict()
    
    result = dict(
        found=False,
        original_path='',
        path=''
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        module.exit_json(**result)

    get_path_cmd="Write-Host \$env:PATH"
    resp = run_process(get_path_cmd)
    if resp.returncode != 0:
        module.fail_json(msg="Error when retrieving path from windows host.\nReason : %{}".format(resp.stderr), **result)
    else:
        b = resp.stdout
        win_path = b.decode('utf-8')
    
    arr = win_path.split(';')
    for el in arr:
        match = search(r'^C:\\Users\\.*\\AppData\\Local\\Programs\\Microsoft VS Code\\bin$', el)
        if match:
            original_path = match.string

            linux_path = original_path.replace('C:', 'c')
            linux_path = linux_path.replace('\\', '/')
            linux_path = "/mnt/{}".format(linux_path)
            linux_path = linux_path.replace(' ', '\ ')

            result['found'] = True
            result['original_path'] = original_path
            result['path'] = linux_path

            # Return the response
            module.exit_json(**result)

    result['found'] = False
    # Return the response
    module.exit_json(**result)


def main():
    run_module()

if __name__ == '__main__':
    main()