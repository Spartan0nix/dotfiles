#!/usr/bin/python

# Copyright: (c) 2022, Léo HUMBLOT <dev.humblole@gmail.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
__metaclass__ = type

DOCUMENTATION = r'''
---
module: github_release

short_description: Return the latest release asset download URL from a github repository.

version_added: "1.0.0"

description: This module allow to return the latest release asset download URL from a github repository.

options:
    repo_name:
        description: Name of the Github repository
        required: true
        type: str
    repo_owner:
        description: Name of the Github repository owner
        required: true
        type: str
    asset_name:
        description: Name of the asset to look for in the release
        required: true
        type: str

extends_documentation_fragment:
    - local.dotfiles.github_release_doc

author:
    - Léo HUMBLOT (@Spartan0nix)
'''

EXAMPLES = r'''
# Get the .deb package from the Neovim repo
- name: Get deb package
  local.dotfiles.github_release:
    repo_name: neovim
    repo_owner: neovim
    asset_name: nvim-linux64.deb

# fail the module
- name: Test failure of the module
  local.dotfiles.github_release:
    repo_name: neovim-non-existant
    repo_owner: neovim-random
    asset_name: nvim-linux64.extension
'''

RETURN = r'''
# Sample of possible returned values
found:
    description: Indicate if the URL was found
    type: str
    returned: always
    sample: 'True'
url:
    description: The browser download url for the desired asset
    type: str
    returned: always
    sample: 'https://github.com/neovim/neovim/releases/download/v0.7.2/nvim-linux64.deb'
'''

from ansible.module_utils.basic import AnsibleModule
import requests

def run_module():
    module_args = dict(
        repo_name=dict(type='str', required=True),
        repo_owner=dict(type='str', required=True),
        asset_name=dict(type='str', required=True)
    )
    
    result = dict(
        found=False,
        url='',
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


    # Build the URL to get the latest release
    url = "https://api.github.com/repos/{}/{}/releases/latest".format(module.params['repo_owner'], module.params['repo_name'])
    # Execute the request
    r = requests.get(url)
    # Handle the response as json
    latest_request = r.json()
    
    # Check if a 404 Not Found response was returned
    if r.status_code == 404:
        module.fail_json(msg="The requested URL '{}' was not found".format(url), **result)

    # Check if a not found response was returned without a 404 reponse code
    if 'message' in latest_request:
        if latest_request['message'] == 'Not Found':
                module.fail_json(msg="The requested URL '{}' was not found".format(url), **result)
    
    # Parse the different assets of the release
    release_assets = latest_request['assets']
    for asset in release_assets:
        # Search for the desired asset
        if (asset['name'].__contains__(module.params['asset_name'])):
            result['url'] = asset['browser_download_url']
            result['found'] = True
            break

    # Return the response
    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()