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
from scripts.deploy_retrocats import deploy_retro_cats, deploy_retro_cats_metadata
import pytest

STATIC_RANDOMNESS = 777


def test_initializer_called_only_once():  # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account()
    retro_cats = deploy_retro_cats()
    with pytest.raises(exceptions.VirtualMachineError):
        retro_cats.initialize(
            get_contract("vrf_coordinator").address,
            get_contract("link_token").address,
            config["networks"][network.show_active()]["keyhash"],
            config["networks"][network.show_active()]["fee"],
            RetroCatsMetadata[-1].address,
            config["networks"][network.show_active()].get(
                "keeper_registry", account.address
            ),
            {"from": account},
        )


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


def test_need_link_to_mint():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    # Should call the Chainlink VRF
    account = get_account(
        index=1
    )  # Remeber, the admin is the proxy contract so we can do this
    retro_cats = deploy_retro_cats()
    with pytest.raises(exceptions.VirtualMachineError):
        receipt = retro_cats.mint_cat({"from": account})
        receipt.wait(1)


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
    requested_tx = retro_cats.mint_cat({"from": account})
    requested_tx.wait(1)
    assert requested_tx.events["requestedNewChainlinkVRF"]["tokenId"] == 0
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
    requested_tx = retro_cats.mint_cat({"from": account})
    requested_tx.wait(1)
    assert requested_tx.events["requestedKeeperRNG"]["tokenId"] == 1
    assert retro_cats.checkUpkeep.call("")[0] is True
    assert retro_cats.s_tokenIdRandomnessNeededQueue(0) == 1
    return retro_cats


def test_keepers_performing_upkeep():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    # And checkupkeep should be true
    account = get_account()  # Account is also the keeper by default
    retro_cats = test_mint_second_cat()
    upkeep_tx = retro_cats.performUpkeep("", {"from": account})
    upkeep_tx.wait(1)
    with pytest.raises(exceptions.VirtualMachineError):
        retro_cats.s_tokenIdRandomnessNeededQueue(0)
    assert upkeep_tx.events["randomNumberAssigned"]["tokenId"] == 1


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
    for x in range(13):
        requested_tx = retro_cats.mint_cat({"from": account})
        requested_tx.wait(1)
    assert retro_cats.s_tokenCounter() == 15
    requested_tx = retro_cats.mint_cat({"from": account})
    requested_tx.wait(1)
    assert requested_tx.events["requestedNewChainlinkVRF"]["tokenId"] == 15
    assert requested_tx.events["requestedNewChainlinkVRF"]["requestId"] is not None
