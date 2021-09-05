#!/usr/bin/python3
from brownie import (
    RetroCats,
    RetroCatsMetadata,
    TransparentUpgradeableProxy,
    ProxyAdmin,
    config,
    network,
    Contract,
)
from scripts.helpful_scripts import get_account, get_contract


def deploy_retro_cats_metadata():
    account = get_account()
    # Metadata doesn't need to be behind a proxy
    retro_cats_metadata = RetroCatsMetadata.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print(f"Let's get a value to see if this is working: {retro_cats_metadata.purr()}")
    return retro_cats_metadata


def deploy_retro_cats(retro_cats_metadata=None):
    account = get_account()
    if not retro_cats_metadata and len(RetroCatsMetadata) == 0:
        deploy_retro_cats_metadata()
    retro_cats = RetroCats.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    proxy_admin = ProxyAdmin.deploy({"from": account})
    # If we want an intializer function we can add
    # `initializer=box.store, 1`
    # to simulate the initializer being the `store` function
    # with a `newValue` of 1
    retro_cats_encoded_initializer_function = retro_cats.initialize.encode_input(
        get_contract("vrf_coordinator").address,
        get_contract("link_token").address,
        # Had a snafu with encoding these for some reason
        config["networks"][network.show_active()]["keyhash"],
        config["networks"][network.show_active()]["fee"],
        RetroCatsMetadata[-1].address,
        config["networks"][network.show_active()].get(
            "keeper_registry", account.address
        ),
    )
    proxy = TransparentUpgradeableProxy.deploy(
        retro_cats.address,
        # account.address,
        proxy_admin.address,
        retro_cats_encoded_initializer_function,
        {"from": account, "gas_limit": 1000000},
    )
    proxy_retro_cats = Contract.from_abi("RetroCats", proxy.address, retro_cats.abi)
    print(f"Here is our contract name: {proxy_retro_cats.name()}")
    return proxy_retro_cats


def main():
    deploy_retro_cats_metadata()
    deploy_retro_cats()
