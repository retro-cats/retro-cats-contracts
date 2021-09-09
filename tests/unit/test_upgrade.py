import pytest
from brownie import (
    RetroCats,
    RetroCatsUpgraded,
    TransparentUpgradeableProxy,
    ProxyAdmin,
    Contract,
    network,
    config,
    exceptions,
)
from scripts.helpful_scripts import (
    get_account,
    upgrade,
    get_contract,
)
from scripts.deploy_retrocats import deploy_retro_cats_metadata


def test_proxy_upgrades():
    account = get_account()
    retro_cats_metadata = deploy_retro_cats_metadata()
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
        retro_cats_metadata,
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

    assert proxy_retro_cats.checkUpkeep.call("")[0] is False
    assert proxy_retro_cats.s_vrfCallInterval() == 15
    proxy_upgraded_abi = Contract.from_abi(
        "RetroCatsUpgraded", proxy_retro_cats.address, RetroCatsUpgraded.abi
    )
    with pytest.raises(exceptions.VirtualMachineError):
        proxy_upgraded_abi.test_working()

    retro_cats_upgraded = RetroCatsUpgraded.deploy(
        {"from": account},
    )

    upgrade(
        account,
        proxy,
        retro_cats_upgraded.address,
        proxy_admin_contract=proxy_admin,
    )
    with pytest.raises(exceptions.VirtualMachineError):
        proxy_retro_cats.checkUpkeep.call("")[0]
        proxy_retro_cats.s_vrfCallInterval()

    assert proxy_upgraded_abi.test_working() is True
