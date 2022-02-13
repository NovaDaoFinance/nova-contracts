import pytest
from brownie import exceptions


def test_add_withdraw_approved_sellers(contracts,accounts):
    aphm = contracts["aphm"]
    developer = contracts['developer']
    newSeller = accounts[1]
    aphm.addApprovedAddress(newSeller, {"from": developer})
    aphm.mint(newSeller, 1e18)
    assert aphm.balanceOf(newSeller) == 1e18
    with pytest.raises(exceptions.VirtualMachineError):
        aphm.removeApprovedAddress(newSeller, {'from': accounts[2]})

    # Add a group of accounts
    newSeller2 = accounts[2]
    newSeller3 = accounts[3]
    newSeller4 = accounts[4]
    sellerList = []
    sellerList.extend([newSeller2, newSeller3])
    aphm.addApprovedAddresses(sellerList, {"from": developer})
    aphm.mint(newSeller2, 2e18, {"from": developer})
    aphm.mint(newSeller3, 3e18, {"from": developer})

    assert aphm.balanceOf(newSeller2) == 2e18
    assert aphm.balanceOf(newSeller3) == 3e18
    assert aphm.isApprovedAddress(newSeller2) is True
    assert aphm.isApprovedAddress(newSeller3) is True
    with pytest.raises(exceptions.VirtualMachineError):
        aphm.mint(newSeller4,1e18,  {"from": newSeller3 })

    #Fail attempt to Remove a group of accounts
    with pytest.raises(exceptions.VirtualMachineError):
            aphm.removeApprovedAddresses(sellerList, {'from': newSeller4})

    #Successful attempt to Remove a group of accounts
    aphm.removeApprovedAddresses(sellerList, {'from': developer})
    assert aphm.isApprovedAddress(newSeller2) is False
    assert aphm.isApprovedAddress(newSeller3) is False


def test_max_cap(contracts, accounts):
    aphm = contracts["aphm"]
    developer = contracts['developer']
    member = accounts[1]
    member2 = accounts[2]
    aphm.mint(member, 74e20, {"from": developer})
    assert aphm.balanceOf(member) == 74e20
    #Based on Total Supply 
    with pytest.raises(exceptions.VirtualMachineError):
        aphm.mint(member2, 2e20, {"from": developer})


def test_mint_burn(contracts, accounts): 
    aphm = contracts["aphm"]
    developer = contracts['developer']
    member = accounts[1]

    aphm.mint(member, 1e20)
    aphm.mint(developer, 1e20)
    assert aphm.balanceOf(member) == 1e20
    assert aphm.totalSupply() == 2e20

    aphm.burn(developer, 1e18, {"from": developer})
    assert aphm.balanceOf(developer) == 1e20 - 1e18


def test_transfer(contracts, chain, accounts): 
    aphm = contracts["aphm"]
    developer = contracts['developer']
    member = accounts[1]
    aphm.mint(member, 1e18)
    aphm.mint(developer, 2e18)
    aphm.addApprovedAddress(developer)
    aphm.addApprovedAddress(member)
    aphm.transfer(accounts[2], aphm.balanceOf(developer), {'from': developer})
    aphm.approve(developer, aphm.balanceOf(accounts[1]), {"from": member})
    aphm.transferFrom(member, developer, aphm.balanceOf(accounts[1]), {"from":  developer})
    assert aphm.balanceOf(developer) == 1e18
    assert aphm.balanceOf(accounts[1]) == 0
    assert aphm.balanceOf(accounts[2]) == 2e18

    #These transfer call should fail since caller is not approved seller 
    aphm.mint(accounts[2], 1e18)
    with pytest.raises(exceptions.VirtualMachineError):
        aphm.transfer(accounts[3], aphm.balanceOf(member), {'from': accounts[2]})