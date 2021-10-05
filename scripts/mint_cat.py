from brownie import (
    RetroCats,
    Contract,
)

from scripts.helpful_scripts import get_account, fund_with_link, get_contract
import time

AMOUNT_OF_CATS = 6


def mint_cats():
    account = get_account()
    retro_cats = RetroCats[-1]
    link_token = get_contract("link_token")
    if link_token.balanceOf(retro_cats) < 1500000000000000000:
        tx = fund_with_link(retro_cats)
        tx.wait(1)
    tx = retro_cats.mint_cats(
        AMOUNT_OF_CATS,
        {"from": account, "value": retro_cats.s_catfee() * AMOUNT_OF_CATS},
    )
    # print(f"{proxy_retro_cats.s_fee()}")
    tx.wait(1)
    token_id = tx.events["requestedNewCat"]["tokenId"]
    print("Waiting for that cat...")
    time.sleep(180)
    print(
        f"Got a new cat and it's randomness: \n token_id: {token_id} \n rng: {retro_cats.s_tokenIdToRandomNumber(token_id)}"
    )


def main():
    mint_cats()
