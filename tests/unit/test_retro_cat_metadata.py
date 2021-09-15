from scripts.deploy_retrocats import deploy_retro_cats_metadata
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS
from brownie import network
import pytest

STATIC_RANDOMNESS = 777


def test_rng_to_cat():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    retro_cats_metadata = deploy_retro_cats_metadata()
    cat = retro_cats_metadata.rngToCat(STATIC_RANDOMNESS)
    assert cat == (1, 10, 8, 6, 16, 0, 8, 9, 5, 10, 6)


def test_creating_cat_images_doesnt_revert():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    retro_cats_metadata = deploy_retro_cats_metadata()
    for x in range(100):
        print(retro_cats_metadata.rngToCat(x))
        assert retro_cats_metadata.rngToCat(x) is not None
