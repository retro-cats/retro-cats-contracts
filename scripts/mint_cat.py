from brownie import (
    config,
    network,
    RetroCatsMetadata,
    RetroCats,
    exceptions,
    TransparentUpgradeableProxy,
    Contract,
    accounts,
)

# from scripts.helpful_scripts import get_account, get_contract, fund_with_link


def mint_cat():
    account = accounts.add(config["wallets"]["from_key"])
    proxy = TransparentUpgradeableProxy[-1]
    proxy_retro_cats = Contract.from_abi("RetroCats", proxy.address, RetroCats.abi)
    proxy_retro_cats.mint_cat({"from": account})
    print(f"{proxy_retro_cats.s_fee()}")


def main():
    mint_cat()
