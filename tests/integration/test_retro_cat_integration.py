from brownie import (
    network,
    exceptions,
)
from scripts.deploy_retrocats import deploy_retro_cats_metadata, deploy_retro_cats
from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    get_account,
    fund_with_link,
)
import pytest
import time

# For our integration tests here, we are going to assume you:
# 1. Ran the deploy script
# 2. Registered your keepers


# @pytest.skip("We have to be a bit manual here...")
def test_minting_first_cat_and_waiting():
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    # Should call the Chainlink VRF
    account = (
        get_account()
    )  # Remeber, the admin is the proxy contract so we can do this
    retro_cats_metadata = deploy_retro_cats_metadata()
    retro_cats = deploy_retro_cats()
    tx = fund_with_link(retro_cats.address)
    tx.wait(1)
    assert retro_cats.s_tokenIdToRandomNumber(0) == 0
    cat_price = retro_cats.s_catfee()
    requested_tx = retro_cats.mint_cats({"from": account, "value": cat_price})
    requested_tx.wait(1)
    assert requested_tx.events["requestedNewCat"]["tokenId"] == 0

    # Wait for Chainlink VRF to respond
    time.sleep(180)
    assert retro_cats.s_tokenIdToRandomNumber(0) != 0
    rng = retro_cats.s_tokenIdToRandomNumber(0)
    print(f"Here is our random number: {rng}")
    print(f"Here is our cat: {retro_cats_metadata.rngToCat(rng)}")
