from brownie import (
    RetroCats,
    Contract,
)

from scripts.helpful_scripts import get_account


def set_interval():
    account = get_account()
    retro_cats = RetroCats[-1]
    tx = retro_cats.setVRFCallInterval(1, {"from": account})
    tx.wait(1)


def main():
    set_interval()
