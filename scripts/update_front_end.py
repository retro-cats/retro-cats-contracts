import yaml
import json
import os
import shutil

FRONT_END_FOLDER = "../retro-cats-front-end-js/src/"


def update_front_end():
    # Send the build folder
    copy_folders_to_front_end("./build", f"{FRONT_END_FOLDER}chain-info")

    # Sending the front end our config in JSON format
    with open("brownie-config.yaml", "r") as brownie_config:
        config_dict = yaml.load(brownie_config, Loader=yaml.FullLoader)
        with open(f"{FRONT_END_FOLDER}brownie-config.json", "w") as brownie_config_json:
            json.dump(config_dict, brownie_config_json)
    print("Front end updated!")


def copy_folders_to_front_end(src, dest):
    if os.path.exists(dest):
        shutil.rmtree(dest)
    shutil.copytree(src, dest)


def main():
    update_front_end()
