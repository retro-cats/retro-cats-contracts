from brownie import (
    RetroCats,
    TransparentUpgradeableProxy,
    Contract,
)

from scripts.helpful_scripts import get_account, fund_with_link
import time


def mint_cat():
    account = get_account()
    proxy = TransparentUpgradeableProxy[-1]
    proxy_retro_cats = Contract.from_abi("RetroCats", proxy.address, RetroCats.abi)
    tx = fund_with_link(proxy_retro_cats)
    tx.wait(1)
    tx = proxy_retro_cats.mint_cat({"from": account})
    # print(f"{proxy_retro_cats.s_fee()}")
    tx.wait(1)
    token_id = tx.events["requestedNewCat"]["tokenId"]
    print("Waiting for that cat...")
    time.sleep(120)
    print(
        f"Got a new cat and it's randomness: \n token_id: {token_id} \n rng: {proxy_retro_cats.s_tokenIdToRandomNumber(token_id)}"
    )


def main():
    mint_cat()
