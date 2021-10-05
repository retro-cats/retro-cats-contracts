#!/usr/bin/python3
from brownie import (
    RetroCats,
    RetroCatsMetadata,
    RetroCatsRaffle,
    config,
    network,
)
from scripts.helpful_scripts import get_account, get_contract
from scripts.set_base_uri import set_base_uri
from scripts.update_front_end import update_front_end


def deploy_retro_cats_metadata():
    account = get_account()
    retro_cats_metadata = RetroCatsMetadata.deploy(
        {"from": account},
        # publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print(f"Let's get a value to see if this is working: {retro_cats_metadata.purr()}")
    return retro_cats_metadata


def deploy_retro_cats_raffle(retrocats_address):
    account = get_account()
    retro_cats_metadata = RetroCatsRaffle.deploy(
        get_contract("vrf_coordinator").address,
        get_contract("link_token").address,
        config["networks"][network.show_active()]["keyhash"],
        config["networks"][network.show_active()]["fee"],
        retrocats_address,
        {"from": account},
        # publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    return retro_cats_metadata


def deploy_retro_cats(retro_cats_metadata=None, retro_cats_raffle=None):
    account = get_account()
    if not retro_cats_metadata and len(RetroCatsMetadata) == 0:
        deploy_retro_cats_metadata()
    retro_cats = RetroCats.deploy(
        get_contract("vrf_coordinator").address,
        get_contract("link_token").address,
        # Had a snafu with encoding these for some reason
        config["networks"][network.show_active()]["keyhash"],
        config["networks"][network.show_active()]["fee"],
        RetroCatsMetadata[-1].address,
        {"from": account},
        # publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print(f"Here is our contract name: {retro_cats.name()}")
    if not retro_cats_raffle and len(RetroCatsRaffle) == 0:
        deploy_retro_cats_raffle(retro_cats.address)
    if network.show_active() == "rinkeby":
        set_base_uri()
        update_front_end()
    return retro_cats


def main():
    deploy_retro_cats_metadata()
    deploy_retro_cats()
