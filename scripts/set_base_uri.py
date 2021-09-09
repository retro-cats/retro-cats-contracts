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
    tx = proxy_retro_cats._setBaseURI(
        "https://us-central1-retro-cats.cloudfunctions.net/retro-cats-function-rinkeby?token_id=",
        {"from": account},
    )
    tx.wait(1)


def main():
    set_interval()
