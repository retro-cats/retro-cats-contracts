from brownie import (
    config,
    network,
    RetroCatsMetadata,
    exceptions,
    VRFCoordinatorMock,
)

from scripts.helpful_scripts import (
    get_account,
    get_contract,
    fund_with_link,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)
from scripts.deploy_retrocats import deploy_retro_cats
import pytest

STATIC_RANDOMNESS = 777


def test_owner_set_properly():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    retro_cats = deploy_retro_cats()
    assert retro_cats.owner() == get_account()


def test_fee_set_properly():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    retro_cats = deploy_retro_cats()
    assert retro_cats.s_fee() == config["networks"][network.show_active()]["fee"]
    assert retro_cats.s_vrfCallInterval() == 15


def test_need_link_to_mint():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    # Should call the Chainlink VRF
    account = get_account(
        index=1
    )  # Remeber, the admin is the proxy contract so we can do this
    retro_cats = deploy_retro_cats()
    amount_of_cats = 1
    with pytest.raises(exceptions.VirtualMachineError):
        receipt = retro_cats.mint_cat(amount_of_cats, {"from": account})
        receipt.wait(1)


def test_need_eth_to_mint():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    # Should call the Chainlink VRF
    account = (
        get_account()
    )  # Remeber, the admin is the proxy contract so we can do this
    retro_cats = deploy_retro_cats()
    tx = fund_with_link(retro_cats)
    tx.wait(1)
    amount_of_cats = 1
    with pytest.raises(exceptions.VirtualMachineError):
        requested_tx = retro_cats.mint_cat(amount_of_cats, {"from": account})
        requested_tx.wait(1)


def test_mint_first_cat():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    # Should call the Chainlink VRF
    account = (
        get_account()
    )  # Remeber, the admin is the proxy contract so we can do this
    retro_cats = deploy_retro_cats()
    tx = fund_with_link(retro_cats)
    tx.wait(1)
    cat_price = retro_cats.s_catfee()
    amount_of_cats = 1
    requested_tx = retro_cats.mint_cat(
        amount_of_cats, {"from": account, "value": cat_price}
    )
    requested_tx.wait(1)
    assert requested_tx.events["requestedNewCat"]["tokenId"] == 0
    assert requested_tx.events["requestedNewChainlinkVRF"]["requestId"] is not None
    return retro_cats, requested_tx


def test_chainlink_vrf_fulfillment():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account()
    retro_cats, requested_tx = test_mint_first_cat()
    mock_chainlink_vrf = VRFCoordinatorMock[-1]
    vrf_tx = mock_chainlink_vrf.callBackWithRandomness(
        requested_tx.events["requestedNewChainlinkVRF"]["requestId"],
        STATIC_RANDOMNESS,
        retro_cats.address,
        {"from": account},
    )
    assert vrf_tx.events["randomNumberAssigned"]["tokenId"] == 0


def test_mint_second_cat():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    # Should call the Chainlink VRF
    # And checkupkeep should be true
    account = get_account()
    retro_cats, _ = test_mint_first_cat()
    with pytest.raises(exceptions.VirtualMachineError):
        retro_cats.s_tokenIdRandomnessNeededQueue(0)
    tx = fund_with_link(retro_cats)
    tx.wait(1)
    cat_price = retro_cats.s_catfee()
    amount_of_cats = 1
    requested_tx = retro_cats.mint_cat(
        amount_of_cats, {"from": account, "value": cat_price}
    )
    requested_tx.wait(1)
    assert requested_tx.events["requestedNewCat"]["tokenId"] == 1
    assert retro_cats.checkUpkeep.call("")[0] is True
    assert retro_cats.s_tokenIdRandomnessNeededQueue(0) == 1
    return retro_cats


def test_mint_many_cats():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    # Should call the Chainlink VRF
    # And checkupkeep should be true
    account = get_account()
    retro_cats, _ = test_mint_first_cat()
    with pytest.raises(exceptions.VirtualMachineError):
        retro_cats.s_tokenIdRandomnessNeededQueue(0)
    tx = fund_with_link(retro_cats)
    tx.wait(1)
    cat_price = retro_cats.s_catfee()
    with pytest.raises(exceptions.VirtualMachineError):
        # This test too many cats minted at once
        amount_of_cats = 15
        requested_tx = retro_cats.mint_cat(
            amount_of_cats, {"from": account, "value": cat_price}
        )
    amount_of_cats = 9
    requested_tx = retro_cats.mint_cat(
        amount_of_cats, {"from": account, "value": cat_price * amount_of_cats}
    )
    requested_tx.wait(1)
    assert requested_tx.events["requestedNewCat"][0]["tokenId"] == 1
    assert (
        requested_tx.events["requestedNewCat"][amount_of_cats - 1]["tokenId"]
        == amount_of_cats
    )
    return retro_cats


def test_can_withdraw_link():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account()
    retro_cats = test_mint_second_cat()
    link_balance = get_contract("link_token").balanceOf(retro_cats)
    starting_account_link_balance = get_contract("link_token").balanceOf(account)
    tx = retro_cats.withdrawLink({"from": account})
    tx.wait(1)
    assert get_contract("link_token").balanceOf(retro_cats) == 0
    assert (
        get_contract("link_token").balanceOf(account)
        == link_balance + starting_account_link_balance
    )


def test_owner_can_withdraw():
    retro_cats = test_mint_second_cat()
    account = get_account()
    bad_account = get_account(index=1)
    with pytest.raises(exceptions.VirtualMachineError):
        retro_cats.withdraw({"from": bad_account})
    assert retro_cats.balance() == retro_cats.s_catfee() * 2
    starting_balance = account.balance()
    tx = retro_cats.withdraw({"from": account})
    tx.wait(1)
    assert account.balance() == starting_balance + retro_cats.s_catfee() * 2
    assert retro_cats.balance() == 0


def test_keepers_performing_upkeep():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    # And checkupkeep should be true
    account = get_account()  # Account is also the keeper by default
    retro_cats = test_mint_second_cat()
    upkeep_tx = retro_cats.performUpkeep("", {"from": account})
    upkeep_tx.wait(1)
    print(upkeep_tx.gas_used)
    with pytest.raises(exceptions.VirtualMachineError):
        retro_cats.s_tokenIdRandomnessNeededQueue(0)
    assert upkeep_tx.events["randomNumberAssigned"]["tokenId"] == 1
    assert retro_cats.checkUpkeep.call("")[0] is False


def test_only_keepers_can_upkeep():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account(index=1)  # Account is also the keeper by default
    retro_cats = test_mint_second_cat()
    with pytest.raises(exceptions.VirtualMachineError):
        retro_cats.performUpkeep("", {"from": account})


def test_chainlink_vrf_called_at_intervals():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account(index=1)  # Account is also the keeper by default
    retro_cats = test_mint_second_cat()  # tokenCounter is now at 2
    cat_price = retro_cats.s_catfee()
    amount_of_cats = 1
    for x in range(13):
        requested_tx = retro_cats.mint_cat(
            amount_of_cats, {"from": account, "value": cat_price}
        )
        requested_tx.wait(1)
    assert retro_cats.s_tokenCounter() == 15
    amount_of_cats = 1
    requested_tx = retro_cats.mint_cat(
        amount_of_cats, {"from": account, "value": cat_price}
    )
    requested_tx.wait(1)
    assert requested_tx.events["requestedNewCat"]["tokenId"] == 15
    assert requested_tx.events["requestedNewChainlinkVRF"]["requestId"] is not None
