from scripts.deploy_retrocats import deploy_retro_cats_metadata

STATIC_RANDOMNESS = 777


def test_rng_to_cat():
    retro_cats_metadata = deploy_retro_cats_metadata()
    cat = retro_cats_metadata.rngToCat(STATIC_RANDOMNESS)
    assert cat == (4, 10, 9, 8, 9, 4, 9, 9, 9, 10, 9)
