import math
import pytest


NULL_ADDR = "0x0000000000000000000000000000000000000000"
# 3 decimals of precision is fine testing purposes, never going to be perfect due to timestamp math
ACCEPTABLE_TIMING_ERROR = 10**15
ACCEPTABLE_ROUNDING_ERROR = 10**10
ONE_YEAR = 365*24*60*60


@pytest.fixture(autouse=True)
def tokens(contracts):
    '''Mint coins for testing'''
    phm = contracts["phm"]
    gphm = contracts["gphm"]
    developer = contracts['developer']
    vault = contracts['vault']

    # We mint to vault to avoid the max holding limit restriction
    # These values are close to the launch values
    phm.mint(vault, 150000*1e18, {'from': developer})
    gphm.mint(vault, 55000*1e18, {'from': developer})


@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    '''Resets the token balance for each test'''
    pass


def test_simple_rebase(contracts):
    phm = contracts["phm"]
    gphm = contracts["gphm"]
    sphm = contracts["sphm"]
    developer = contracts['developer']
    vault = contracts['vault']

    sphm.updateRewardRate(1e15, {"from": developer})  # 0.1%
    assert sphm.rewardRate() == 1e15

    sphm.updateCompoundingPeriodsPeriodYear(1, {"from": developer})
    assert sphm.periodsPerYear() == 1095  # periods updates after rebase
    sphm.updateRewardRate(0, {"from": developer})  # 0%
    sphm.doRebase(1, {"from": developer})  # periods only updates afetr current rebase has processed
    assert sphm.apy() == 1e18
    assert sphm.scalingFactor() == 1e18
    assert sphm.periodsPerYear() == 1  # periods updates after rebase

    # at 1 compounding period per year, apr = apy
    sphm.doRebase(2, {"from": developer})  # periods only updates afetr current rebase has processed
    assert sphm.apr() == sphm.rewardYield()  # rewardRate is 0
    assert sphm.periodsPerYear() == 1  # no change

    sphm.updateRewardRate(1e15, {"from": developer})  # 0.1%
    sphm.doRebase(3, {"from": developer})
    assert abs(
        sphm.apr()/1e18 - (
            (phm.totalSupply()/1e18 * sphm.rewardRate()/1e18 / 
            (sphm.totalSupply()/1e18 + gphm.totalSupply()/1e18) * sphm.scalingFactor()/1e18) *
            sphm.periodsPerYear()  
        )
    ) < ACCEPTABLE_ROUNDING_ERROR
    assert abs(
        sphm.apy()/1e18 - (1 + (phm.totalSupply()/1e18*sphm.rewardRate()/1e18)/(sphm.totalSupply()/1e18 + gphm.totalSupply()/1e18))**sphm.periodsPerYear()
    ) < ACCEPTABLE_ROUNDING_ERROR
    assert sphm.scalingFactor() == 1e18  # Chain isn't running so no time elapsed


def test_real_rebases(contracts, chain):
    phm = contracts["phm"]
    gphm = contracts["gphm"]
    sphm = contracts["sphm"]
    developer = contracts['developer']

    # 1095 rebases a year
    sphm.updateRewardRate(3e15, {"from": developer})  # 0.3%
    chain.sleep(math.ceil(ONE_YEAR/1095))
    chain.mine()
    sphm.doRebase(1, {"from": developer})
    assert sphm.rewardRate() == 3e15
    assert sphm.periodsPerYear() == 1095
    assert abs(
        sphm.apy()/1e18 - (1 + (phm.totalSupply()/1e18*sphm.rewardRate()/1e18)/(sphm.totalSupply()/1e18 + gphm.totalSupply()/1e18))**sphm.periodsPerYear()
    ) < ACCEPTABLE_ROUNDING_ERROR
    assert abs(
        sphm.apr()/1e18 - (
            (phm.totalSupply()/1e18 * sphm.rewardRate()/1e18 / 
            (sphm.totalSupply()/1e18 + gphm.totalSupply()/1e18 * sphm.scalingFactor()/1e18)) *
            sphm.periodsPerYear()  
        )
    ) < ACCEPTABLE_ROUNDING_ERROR
    assert abs(sphm.apy() - 194102.44654093913*1e18) < ACCEPTABLE_ROUNDING_ERROR
    assert abs(sphm.apr() - 12.244090909090907*1e18) < ACCEPTABLE_ROUNDING_ERROR


def test_mint_burn(contracts, chain): 
    sphm = contracts["sphm"]
    developer = contracts['developer']

    sphm.updateCompoundingPeriodsPeriodYear(1, {"from": developer})
    sphm.mint(developer, 1e18)
    sphm.balanceOf(developer) == 1e18
    sphm.totalSupply() == 80e18 + 1e18
    assert sphm.internalBalanceOf(developer) == 1e18

    # Do a rebase. Balances should double given 1 rebase a year.
    chain.sleep(365*24*60*60)
    chain.mine()
    sphm.doRebase(1, {"from": developer})
    assert sphm.internalBalanceOf(developer) - 1e18 < ACCEPTABLE_ROUNDING_ERROR
    assert sphm.balanceOf(developer) - 2e18 < ACCEPTABLE_ROUNDING_ERROR
    assert sphm.totalSupply() - (2e18 + 160e18) < ACCEPTABLE_ROUNDING_ERROR
    sphm.burn(developer, 1e18)
    assert sphm.internalBalanceOf(developer) - 0.5e18 < ACCEPTABLE_ROUNDING_ERROR
    assert sphm.balanceOf(developer) - 1e18 < ACCEPTABLE_ROUNDING_ERROR
    assert sphm.totalSupply() - (3e18 + 160e18) < ACCEPTABLE_ROUNDING_ERROR


def test_transfer(contracts, chain, accounts): 
    sphm = contracts["sphm"]
    developer = contracts['developer']

    sphm.updateCompoundingPeriodsPeriodYear(1, {"from": developer})
    sphm.mint(accounts[1], 1e18)
    chain.sleep(365*12*60*60)
    chain.mine()
    sphm.mint(developer, 1e18)
    sphm.transfer(accounts[2], sphm.balanceOf(developer))
    chain.sleep(365*12*60*60)
    chain.mine()
    sphm.approve(developer, sphm.balanceOf(accounts[1]), {"from": accounts[1]})
    sphm.transferFrom(accounts[1], developer, sphm.balanceOf(accounts[1]), {"from":  developer})
    assert sphm.balanceOf(developer) - 2e18 < ACCEPTABLE_ROUNDING_ERROR
    assert sphm.balanceOf(accounts[1]) - 0 < ACCEPTABLE_ROUNDING_ERROR
    assert sphm.balanceOf(accounts[2]) - 2e18 < ACCEPTABLE_ROUNDING_ERROR