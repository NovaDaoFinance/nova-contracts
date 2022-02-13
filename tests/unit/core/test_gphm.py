import pytest
import brownie


def test_get_past_votes(contracts, chain, accounts): 
    gphm = contracts["gphm"]
    vault = contracts["vault"]
    delegate = accounts[2]
    starting_block = len(chain) - 1

    gphm.mint(vault.address, 200e18)
    gphm.mint(delegate.address, 1e18)

    with brownie.reverts("ERC20Votes: block not yet mined"):
        gphm.getPastVotes(delegate.address, len(chain))

    chain.sleep(20)
    chain.mine()

    assert gphm.getPastVotes(delegate.address, starting_block) == 0
    assert gphm.getPastVotes(delegate.address, len(chain) - 2) == 1e18


def test_get_past_supply(contracts, chain, accounts): 
    gphm = contracts["gphm"]
    vault = contracts["vault"]
    delegate = accounts[2]
    starting_block = len(chain) - 1

    gphm.mint(vault.address, 200e18)
    gphm.mint(delegate.address, 1e18)

    with brownie.reverts("ERC20Votes: block not yet mined"):
        gphm.getPastTotalSupply(len(chain))

    chain.sleep(20)
    chain.mine()

    assert gphm.getPastTotalSupply(starting_block) == 0
    assert gphm.getPastTotalSupply(starting_block + 2) == 201e18


def test_delegate_security(contracts, accounts): 
    gphm = contracts["gphm"]
    DAO = accounts[1]
    delegate = accounts[2]

    assert gphm.delegates(delegate) == delegate
    assert gphm.numCheckpoints(delegate.address) == 0
    gphm.addApprovedDelegatee(DAO)
    gphm.delegate(DAO, {"from": delegate})
    assert gphm.delegates(delegate) == DAO
    assert gphm.numCheckpoints(DAO.address) == 1
    assert gphm.numCheckpoints(delegate.address) == 0
    gphm.delegate('0x0000000000000000000000000000000000000000', {"from": delegate})  # Delegate to 0 address
    assert gphm.delegates(delegate) == delegate
    assert gphm.numCheckpoints(DAO.address) == 1
    assert gphm.numCheckpoints('0x0000000000000000000000000000000000000000') == 0
    assert gphm.numCheckpoints(delegate.address) == 0

    #Should fail since delegatee2 isnt approved Delegatee
    delegatee2 = accounts[3]
    delegator2 = accounts[4]
    with brownie.reverts():
        gphm.delegate(delegatee2, {"from": delegator2})


def test_mint_burn(contracts, accounts): 
    gphm = contracts["gphm"]
    developer = contracts['developer']
    member = accounts[1]
    
    gphm.mint(member, 1e18, {"from": developer})
    gphm.mint(developer, 1e18)
    assert gphm.balanceOf(member) == 1e18
    assert gphm.totalSupply() == 2e18

    gphm.burn(developer, 1e18)
    assert gphm.balanceOf(developer) == 0


def test_transfer(contracts, accounts): 
    gphm = contracts["gphm"]
    vault = contracts["vault"]
    developer = contracts['developer']
    member = accounts[1]

    gphm.mint(member, 1e18)
    gphm.mint(developer, 2e18)
    #Transfer frozen so it should fail
    with brownie.reverts():
        gphm.transfer(accounts[2], gphm.balanceOf(developer), {'from': developer})

    gphm.enableTransfers()
    # Should trigger the wallet supply limit
    with brownie.reverts():
        gphm.transfer(accounts[2], gphm.balanceOf(developer), {'from': developer})
    # Up the supply to prevent supply limits being hit
    gphm.mint(vault.address, 1e20)  
    gphm.transfer(accounts[2], gphm.balanceOf(developer), {'from': developer})
    gphm.approve(developer, gphm.balanceOf(accounts[1]), {"from": member})
    gphm.transferFrom(member, developer, gphm.balanceOf(accounts[1]), {"from":  developer})
    assert gphm.balanceOf(developer) == 1e18
    assert gphm.balanceOf(accounts[1]) == 0
    assert gphm.balanceOf(accounts[2]) == 2e18  
    assert gphm.balanceOf(vault.address) == 1e20  