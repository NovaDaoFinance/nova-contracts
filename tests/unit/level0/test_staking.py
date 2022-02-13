ACCEPTABLE_ROUNDING_ERROR = 1e10


def test_stake_unstake(contracts, accounts, chain):
    admin = contracts["admin"]
    vault = contracts["vault"]
    treasury = contracts["treasury"]
    developer = contracts["developer"]
    phm = contracts["phm"]
    sphm = contracts["sphm"]
    staking = contracts["staking"]
    amount_per_account = 1e18

    phm.mint(vault.address, amount_per_account*23, {"from": developer})
    for i in range(5):  # need a decent amount of sphm staked to prevent overflow
        phm.mint(accounts[i+1].address, amount_per_account, {"from": developer})
    assert phm.balanceOf(accounts[1].address) == amount_per_account
    assert phm.totalSupply() == amount_per_account*5 + amount_per_account*23

    admin.updateStakingRewardRate(3e15, {"from": developer})
    assert sphm.rewardRate() == 3e15
    
    staking.initializeRebasing({"from": developer})
    assert phm.balanceOf(accounts[1].address) == amount_per_account
    assert sphm.balanceOf(accounts[1].address) == 0
    phm.approve(treasury.address, amount_per_account, {"from": accounts[1]})
    staking.stake(accounts[1].address, amount_per_account, {"from": developer})
    assert sphm.balanceOf(accounts[1].address) == amount_per_account
    assert phm.balanceOf(accounts[1].address) == 0
    assert phm.totalSupply() == amount_per_account*5 + amount_per_account*23
    assert staking.rebaseCounter() == 1

    # Do a rebase
    chain.sleep(8*60*60)
    chain.mine()
    staking.attemptRebase({"from": developer})
    assert (sphm.balanceOf(accounts[1].address) - amount_per_account*sphm.scalingFactor()/1e18) < ACCEPTABLE_ROUNDING_ERROR
    x = sphm.balanceOf(accounts[1])
    sphm.approve(treasury.address, sphm.balanceOf(accounts[1]), {"from": accounts[1]})
    staking.unstake(accounts[1].address, sphm.balanceOf(accounts[1]), {"from": developer})
    assert phm.balanceOf(accounts[1].address) == x


def test_wrap_unwrap(contracts, accounts, chain):
    admin = contracts["admin"]
    vault = contracts["vault"]
    treasury = contracts["treasury"]
    developer = contracts["developer"]
    phm = contracts["phm"]
    sphm = contracts["sphm"]
    gphm = contracts["gphm"]
    staking = contracts["staking"]
    amount_per_account = 150e18

    phm.mint(vault.address, amount_per_account*23, {"from": developer})
    phm.mint(accounts[1].address, amount_per_account, {"from": developer})
    assert phm.balanceOf(accounts[1]) == amount_per_account
    assert phm.totalSupply() == amount_per_account*24

    admin.updateStakingRewardRate(3e15, {"from": developer})
    assert sphm.rewardRate() == 3e15
    
    staking.initializeRebasing()
    phm.approve(treasury.address, amount_per_account, {"from": accounts[1]})
    staking.stake(accounts[1], amount_per_account, {"from": developer})
    assert sphm.balanceOf(accounts[1]) == amount_per_account
    assert phm.balanceOf(accounts[1]) == 0

    sphm.approve(treasury.address, amount_per_account, {"from": accounts[1]})
    staking.wrap(accounts[1], amount_per_account, {"from": developer})
    assert gphm.balanceOf(accounts[1]) == amount_per_account
    assert sphm.balanceOf(accounts[1]) == 0

    # Do a rebase
    chain.sleep(8*60*60)
    chain.mine()
    assert gphm.balanceOf(accounts[1]) == amount_per_account
    assert sphm.balanceOf(accounts[1]) == 0
    