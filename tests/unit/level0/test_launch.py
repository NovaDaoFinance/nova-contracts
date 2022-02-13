import pytest
from brownie import exceptions


ACCEPTABLE_ROUNDING_ERROR = 1e14


def test_alpha_swap(contracts, accounts):
    developer = contracts["developer"]
    vault = contracts["vault"]
    treasury = contracts["treasury"]
    swap = contracts["swap"]
    aphm = contracts["aphm"]
    phm = contracts["phm"]
    claimer = accounts[1]

    amount = 1e18
    aphm.mint(claimer, amount)
    phm.mint(vault, 1e21)

    assert phm.balanceOf(claimer) == 0
    assert aphm.balanceOf(claimer) == 1e18
    aphm.approve(treasury.address, aphm.balanceOf(claimer), {"from": claimer})
    swap.swap(claimer.address, {"from": developer})
    assert aphm.balanceOf(claimer) == 0
    assert phm.balanceOf(claimer) == amount


def test_auction_transfer_treasury(contracts, accounts):
    developer = contracts['developer']
    auction = contracts["auction"]
    token = contracts["token4"]
    amount = 1e18

    token.mint(auction, amount)
    auction.transferToTreasury({"from": developer})


def test_founders_unclaimed(contracts, chain):
    developer = contracts["developer"]
    founders = contracts["founders"]
    fphm = contracts["fphm"]

    founders.registerFounder(developer.address, 50*1e18)
    assert founders.remainingAllocation(developer.address) == 50*1e18
    founders.claim(developer.address, {"from": developer})
    assert founders.unclaimedBalance(developer.address) == 0
    assert fphm.balanceOf(developer.address) == 50*1e18

    # Test initial amount
    founders.startVesting({"from": developer})
    assert abs(founders.unclaimedBalance(developer.address) - 12.5*1e18) < ACCEPTABLE_ROUNDING_ERROR

    # Test half amount
    chain.sleep(int(365*24*60*60/2)+1)
    chain.mine()
    assert abs(founders.unclaimedBalance(developer.address) - 31.25*1e18) < ACCEPTABLE_ROUNDING_ERROR

    # Test full amount
    chain.sleep(365*24*60*60)
    chain.mine()
    assert founders.unclaimedBalance(developer.address) == 50*1e18


def test_founders_exercise(contracts, chain):
    developer = contracts["developer"]
    founders = contracts["founders"]
    treasury = contracts["treasury"]
    fphm = contracts["fphm"]
    gphm = contracts["gphm"]

    founders.registerFounder(developer.address, 50*1e18)
    assert founders.remainingAllocation(developer.address) == 50*1e18
    founders.claim(developer.address, {"from": developer})
    assert founders.unclaimedBalance(developer.address) == 0
    assert fphm.balanceOf(developer.address) == 50*1e18
    fphm.approve(treasury.address, 50e18, {"from": developer})

    # Test initial amount
    founders.startVesting({"from": developer})
    assert abs(founders.unclaimedBalance(developer.address) - 12.5*1e18) < ACCEPTABLE_ROUNDING_ERROR
    founders.exercise(developer.address, {"from": developer})
    assert abs(gphm.balanceOf(developer.address) - 12.5e18) < ACCEPTABLE_ROUNDING_ERROR
    assert founders.unclaimedBalance(developer.address) == 0

    # Test half amount
    chain.sleep(int(365*24*60*60/2)+1)
    chain.mine()
    assert abs(founders.unclaimedBalance(developer.address) - 18.75*1e18) < ACCEPTABLE_ROUNDING_ERROR
    founders.exercise(developer.address, {"from": developer})
    assert abs(gphm.balanceOf(developer.address) - 31.25e18) < ACCEPTABLE_ROUNDING_ERROR
    assert founders.unclaimedBalance(developer.address) == 0

    # Test full amount
    chain.sleep(365*24*60*60)
    chain.mine()
    assert abs(founders.unclaimedBalance(developer.address) - 18.75*1e18) < ACCEPTABLE_ROUNDING_ERROR
    founders.exercise(developer.address, {"from": developer})
    assert gphm.balanceOf(developer.address) == 50e18
    assert founders.unclaimedBalance(developer.address) == 0

    # Test full amount
    chain.sleep(1)
    chain.mine()
    assert founders.unclaimedBalance(developer.address) == 0
    with pytest.raises(exceptions.VirtualMachineError):
        founders.exercise(developer.address, {"from": developer})


def test_auction_claim(contracts, accounts):
    developer = contracts["developer"]
    claim = contracts["auctionclaim"]
    treasury = contracts["treasury"]
    aphm = contracts["aphm"]
    token = contracts["token"]

    claim.registerAllotment(accounts[1].address, 50e18, {"from": developer})
    assert claim.remainingAllotment(accounts[1].address) == 50e18 / 50
    claim.registerAllotment(accounts[1].address, 50e18, {"from": developer})
    assert claim.remainingAllotment(accounts[1].address) == 100e18 / 50

    token._mint_for_testing(accounts[1].address, 100e18)
    token.approve(treasury.address, 100e18, {"from": accounts[1]})
    claim.purchase(accounts[1].address)
    assert aphm.balanceOf(accounts[1].address) == 100e18 / 50
    assert claim.remainingAllotment(accounts[1].address) == 0
