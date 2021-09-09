from brownie import (
    RetroCats,
    TransparentUpgradeableProxy,
    Contract,
)

from scripts.helpful_scripts import get_account


def set_interval():
    account = get_account()
    proxy = TransparentUpgradeableProxy[-1]
    proxy_retro_cats = Contract.from_abi("RetroCats", proxy.address, RetroCats.abi)
    tx = proxy_retro_cats.setVRFCallInterval(1, {"from": account})
    tx.wait(1)


def main():
    set_interval()
