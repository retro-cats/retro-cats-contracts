from brownie import (
    config,
    network,
    exceptions,
    VRFCoordinatorMock,
    RetroCatsRaffle,
    RetroCats,
)
import time

from scripts.helpful_scripts import (
    get_account,
    get_contract,
    fund_with_link,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)
from scripts.deploy_retrocats import deploy_retro_cats
import pytest

STATIC_RANDOMNESS = 777


def test_check_upkeep():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    deploy_retro_cats()
    account = get_account()
    retro_cats_raffle = RetroCatsRaffle[-1]
    assert retro_cats_raffle.checkUpkeep("") == (False, "0x")
    retro_cats_raffle.setRaffleOpen(True)
    assert retro_cats_raffle.checkUpkeep("") == (False, "0x")
    tx = fund_with_link(retro_cats_raffle, amount=retro_cats_raffle.s_fee())
    tx.wait(1)
    assert retro_cats_raffle.checkUpkeep("") == (False, "0x")
    account.transfer(retro_cats_raffle.address, retro_cats_raffle.s_winAmount())
    assert retro_cats_raffle.checkUpkeep("") == (False, "0x")
    tx = retro_cats_raffle.setInterval(5, {"from": account})
    tx.wait(1)
    # some_tx is just to make sure a block goes by on our fake blockchain
    time.sleep(6)
    some_tx = account.transfer(
        retro_cats_raffle.address, retro_cats_raffle.s_winAmount()
    )
    some_tx.wait(1)
    assert retro_cats_raffle.checkUpkeep("")[0] is True
    return retro_cats_raffle


def test_perform_upkeep():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account()
    retro_cats_raffle = test_check_upkeep()

    # Setup the minting cats in retro cats
    tx = account.transfer(retro_cats_raffle.address, retro_cats_raffle.s_winAmount())
    tx = fund_with_link(RetroCats[-1])
    mint_cats_tx = RetroCats[-1].mint_cats(
        1, {"from": account, "value": RetroCats[-1].s_catfee()}
    )
    mind_cat_requestId = mint_cats_tx.events["requestedNewCat"]["requestId"]
    tx = get_contract("vrf_coordinator").callBackWithRandomness(
        mind_cat_requestId, 777, RetroCats[-1].address, {"from": get_account()}
    )
    # Setup the raffle now
    starting_time = retro_cats_raffle.s_lastTimeStamp()
    assert retro_cats_raffle.checkUpkeep("")[0] is True
    requested_randomness_tx = retro_cats_raffle.performUpkeep("")
    requested_randomness_tx.wait(1)
    assert retro_cats_raffle.checkUpkeep("")[0] is False
    assert starting_time < retro_cats_raffle.s_lastTimeStamp()

    # Testing the callback
    starting_balance_raffle = retro_cats_raffle.balance()
    starting_balance_account = account.balance()
    requestId = requested_randomness_tx.events["requestedRaffleWinner"]["requestId"]
    tx = get_contract("vrf_coordinator").callBackWithRandomness(
        requestId, 777, retro_cats_raffle.address, {"from": get_account()}
    )
    tx.wait(1)
    # Assert
    assert (
        starting_balance_raffle
        == retro_cats_raffle.balance() + retro_cats_raffle.s_winAmount()
    )
    assert (
        starting_balance_account + retro_cats_raffle.s_winAmount() == account.balance()
    )
