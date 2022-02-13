import brownie


def test_mint_burn(contracts, accounts): 
    phm = contracts["phm"]
    developer = contracts['developer']
    vault = contracts["vault"]
    member = accounts[1]

    #Should this be treasury or vault
    phm.mint(vault, 1e20)
    phm.mint(member, 1e18)
    phm.mint(developer, 1e18)
    amount = 1e20 + 2e18
    assert phm.balanceOf(member) == 1e18
    assert phm.totalSupply() == amount

    phm.burn(developer, 1e18)
    assert phm.balanceOf(developer) == 0

    #Test mint when user has greater than 4.76% ownership
    with brownie.reverts():
        phm.mint(member, 4e18)

    phm.addUncappedHolder(member.address, {"from": developer})
    phm.mint(member, 4e18)
    phm.removeUncappedHolder(member.address, {"from": developer})
    with brownie.reverts():
        phm.mint(member, 4e18)


def test_transfer(contracts, accounts): 
    phm = contracts["phm"]
    developer = contracts['developer']
    member = accounts[1]
    vault = contracts["vault"]

    phm.mint(vault, 1e20)
    phm.mint(member, 1e18)
    phm.mint(developer, 2e18)

    phm.transfer(accounts[2], phm.balanceOf(developer), {'from': developer})
    phm.approve(developer, phm.balanceOf(accounts[1]), {"from": member})
    phm.transferFrom(member, developer, phm.balanceOf(accounts[1]), {"from":  developer})
    assert phm.balanceOf(developer) == 1e18
    assert phm.balanceOf(accounts[1]) == 0
    assert phm.balanceOf(accounts[2]) == 2e18
    phm.mint(accounts[2], 1e18 )
    phm.mint(accounts[3], 3e18 )

    #Test transfer when user has greater than 4.76% ownership
    with brownie.reverts():
        phm.transfer(accounts[3], phm.balanceOf(accounts[2]), {'from': accounts[2]})

    phm.addUncappedHolder(accounts[3].address, {"from": developer})
    phm.transfer(accounts[3], phm.balanceOf(accounts[2]), {'from': accounts[2]})
        

def test_supply_balance(contracts, accounts):
    phm = contracts["phm"]
    sphm = contracts["sphm"]
    gphm = contracts["gphm"]
    fphm = contracts["fphm"]
    vault = contracts["vault"]
    member = accounts[1]

    phm.mint(vault, 1e20)
    sphm.mint(vault, 2e20)
    gphm.mint(vault, 1e20)
    fphm.mint(vault,1e20)

    assert phm.totalSupply() == 5e20

    phm.mint(member, 1e18)
    sphm.mint(member, 2e18)
    gphm.mint(member, 1e18)
    fphm.mint(member,1e18)
    assert phm.balanceAllDenoms(member)










