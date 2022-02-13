import pytest
from brownie import exceptions


def test_add_withdraw_approved_sellers(contracts,accounts):
    fphm = contracts["fphm"]
    developer = contracts['developer']
    newSeller = accounts[1]
    fphm.addApprovedAddress(newSeller, {"from": developer})
    fphm.mint(newSeller, 1e18)
    assert fphm.balanceOf(newSeller) == 1e18
    with pytest.raises(exceptions.VirtualMachineError):
        fphm.removeApprovedAddress(newSeller, {'from': accounts[2]})

    # Add a group of accounts
    newSeller2 = accounts[2]
    newSeller3 = accounts[3]
    newSeller4 = accounts[4]
    sellerList = []
    sellerList.extend([newSeller2, newSeller3])
    fphm.addApprovedAddresses(sellerList, {"from": developer})
    fphm.mint(newSeller2, 2e18, {"from": developer})
    fphm.mint(newSeller3, 3e18, {"from": developer})

    assert fphm.balanceOf(newSeller2) == 2e18
    assert fphm.balanceOf(newSeller3) == 3e18
    assert fphm.isApprovedAddress(newSeller2) is True
    assert fphm.isApprovedAddress(newSeller3) is True
    with pytest.raises(exceptions.VirtualMachineError):
        fphm.mint(newSeller4,1e18,  {"from": newSeller3 })

    #Fail attempt to Remove a group of accounts
    with pytest.raises(exceptions.VirtualMachineError):
            fphm.removeApprovedAddresses(sellerList, {'from': newSeller4})

    #Successful attempt to Remove a group of accounts
    fphm.removeApprovedAddresses(sellerList, {'from': developer})
    assert fphm.isApprovedAddress(newSeller2) is False
    assert fphm.isApprovedAddress(newSeller3) is False


def test_max_cap(contracts, accounts):
    fphm = contracts["fphm"]
    developer = contracts['developer']
    member = accounts[1]
    member2 = accounts[2]
    fphm.mint(member, 24e20, {"from": developer})
    assert fphm.balanceOf(member) == 24e20
    #Based on Total Supply 
    with pytest.raises(exceptions.VirtualMachineError):
        fphm.mint(member2, 2e20, {"from": developer})


def test_mint_burn(contracts, accounts): 
    fphm = contracts["fphm"]
    developer = contracts['developer']
    member = accounts[1]

    fphm.mint(member, 1e20)
    fphm.mint(developer, 1e20)
    assert fphm.balanceOf(member) == 1e20
    assert fphm.totalSupply() == 2e20

    fphm.burn(developer, 1e18)
    assert fphm.balanceOf(developer) == 1e20 - 1e18


def test_transfer(contracts, chain, accounts): 
    fphm = contracts["fphm"]
    developer = contracts['developer']
    member = accounts[1]

    fphm.mint(member, 1e18)
    fphm.mint(developer, 2e18)
    fphm.addApprovedAddress(developer)
    fphm.addApprovedAddress(member)
    fphm.transfer(accounts[2], fphm.balanceOf(developer), {'from': developer})
    fphm.approve(developer, fphm.balanceOf(accounts[1]), {"from": member})
    fphm.transferFrom(member, developer, fphm.balanceOf(accounts[1]), {"from":  developer})
    assert fphm.balanceOf(developer) == 1e18
    assert fphm.balanceOf(accounts[1]) == 0
    assert fphm.balanceOf(accounts[2]) == 2e18

    #These transfer call should fail since caller is not approved seller 
    fphm.mint(accounts[2], 1e18)
    with pytest.raises(exceptions.VirtualMachineError):
        fphm.transfer(accounts[3], fphm.balanceOf(member), {'from': accounts[2]})