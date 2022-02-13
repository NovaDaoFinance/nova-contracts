import pytest
from brownie import exceptions
from brownie.convert import to_bytes

ONE_DAY = b"one_day_bond"
THREE_DAY = b"three_day_bond"
FIVE_DAY = b"five_day_bond"
# 3 decimals of precision is fine testing purposes, never going to be perfect due to timestamp math
ACCEPTABLE_TIMING_ERROR = 10**15


def test_bond_setup(contracts):
    admin = contracts["admin"]
    BONDS = contracts['bonds']
    developer= contracts['developer']

    for t in BONDS:
        assert admin.isValidTokenForBond(t) == True

    admin.removeMultipleTokensToBondingList(BONDS, {"from": developer})

    for t in BONDS:
        assert admin.isValidTokenForBond(t) == False
        
    a, b = admin.infoOfBondType(ONE_DAY)
    assert a == True
    assert b == 24 * 60 * 60

    a, b = admin.infoOfBondType(THREE_DAY)
    assert a == True
    assert b == 3 * 24 * 60 * 60

    a, b = admin.infoOfBondType(FIVE_DAY)
    assert a == True
    assert b == 5 * 24 * 60 * 60

    admin.removeBondType(ONE_DAY, {"from": developer})
    admin.removeBondType(THREE_DAY, {"from": developer})
    admin.removeBondType(FIVE_DAY, {"from": developer})

    a, b = admin.infoOfBondType(ONE_DAY)
    assert a == False
    assert b == 0

    a, b = admin.infoOfBondType(THREE_DAY)
    assert a == False
    assert b == 0

    a, b = admin.infoOfBondType(FIVE_DAY)
    assert a == False
    assert b == 0


def test_invalid_bonding_token(contracts):
    bonding = contracts["bonding"]
    developer= contracts['developer']

    with pytest.raises(exceptions.VirtualMachineError):
        bonding.createBond(developer, 1000**18, contracts["token2"], to_bytes('0x00','bytes32'))

    
# def test_basic_bonding_token(contracts):
#     bonding = contracts["bonding"]
#     treasury = contracts["treasury"]
#     vault = contracts["vault"]
#     admin = contracts["admin"]
#     token = contracts["token"]
#     phm = contracts["phm"]
#     admin.enableDebugMode()
#     admin.addMultipleTokensToBondingList([token.address], {"from": accounts[0]})  
#     token._mint_for_testing(accounts[1], 500)
#     token.approve(treasury.address, 500, {"from": accounts[1]})  
#     admin.addMultipleTokensToBondingList(contracts["bonds"], {"from": accounts[0]})
#     admin.setBondingMultiplierFor(ONE_DAY, token.address, 2*10**18, {"from": accounts[0]}) # 50 % 
#     assert admin.bondingMultiplierFor(ONE_DAY, token.address) == 2*(10**18)
#     result = bonding.createBond(500, token.address, ONE_DAY, {"from": accounts[1]}) # 50 % 
#     # in the debug mode 5 token is 1 phm, 500 token is 100 phm but @ 50% discount == 200 phm
#     assert result.return_value == 200
#     assert token.balanceOf(vault.address) == 500
#     assert phm.balanceOf(vault.address) == 200

#     chain.sleep(24 * 60 * 60) # time travel to the end of the bond.

#     bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#     assert token.balanceOf(vault.address) == 500
#     assert phm.balanceOf(vault.address) == 0
#     assert phm.balanceOf(accounts[1].address) == 200

#     bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         assert phm.balanceOf(accounts[1].address) == 200

#     def test_basic_bonding_token_auto_stake(contracts):
#         bonding = contracts["bonding"]
#         treasury = contracts["treasury"]
#         vault = contracts["vault"]
#         admin = contracts["admin"]
#         token = contracts["token"]
#         phm = contracts["phm"]
#         sphm = contracts["sphm"]
#         admin.enableDebugMode()
#         admin.addMultipleTokensToBondingList([token.address], {"from": accounts[0]})  
#         token._mint_for_testing(accounts[1], 500)
#         token.approve(treasury.address, 500, {"from": accounts[1]})  
#         admin.addMultipleTokensToBondingList(BONDS, {"from": accounts[0]})
#         admin.setBondingMultiplierFor(ONE_DAY, token.address, 2*10**18, {"from": accounts[0]}) # 50 % 
#         assert admin.bondingMultiplierFor(ONE_DAY, token.address) == 2*(10**18)
#         result = bonding.createBond(500, token.address, ONE_DAY, {"from": accounts[1]}) # 50 % 
#         # in the debug mode 5 token is 1 phm, 500 token is 100 phm but @ 50% discount == 200 phm
#         assert result.return_value == 200
#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 200
#         assert sphm.balanceOf(accounts[0].address) == 0
#         assert phm.balanceOf(accounts[0].address) == 0

#         chain.sleep(24 * 60 * 60) # time travel to the end of the bond.

#         bonding.redeemBonds(True, {"from": accounts[1]}) # auto stake gang

#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 0
#         assert sphm.balanceOf(accounts[1].address) == 200
#         assert phm.balanceOf(accounts[1].address) == 0

#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake
#         bonding.redeemBonds(True, {"from": accounts[1]}) # autostake
#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(accounts[1].address) == 0
#         assert sphm.balanceOf(accounts[1].address) == 200

#     def test_zero_percent_bond(contracts):
#         bonding = contracts["bonding"]
#         treasury = contracts["treasury"]
#         vault = contracts["vault"]
#         admin = contracts["admin"]
#         token = contracts["token"]
#         phm = contracts["phm"]
#         admin.enableDebugMode()
#         admin.addMultipleTokensToBondingList([token.address], {"from": accounts[0]})  
#         token._mint_for_testing(accounts[1], 500)
#         token.approve(treasury.address, 500, {"from": accounts[1]})  
#         admin.addMultipleTokensToBondingList(BONDS, {"from": accounts[0]})
#         admin.setBondingMultiplierFor(ONE_DAY, token.address, 10**18, {"from": accounts[0]}) # 50 % 
#         assert admin.bondingMultiplierFor(ONE_DAY, token.address) == (10**18)
#         result = bonding.createBond(500, token.address, ONE_DAY, {"from": accounts[1]}) # 50 % 
#         # in the debug mode 5 token is 1 phm, 500 token is 100 phm but @ 50% discount == 200 phm
#         assert result.return_value == 100
#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 100

#         chain.sleep(24 * 60 * 60) # time travel to the end of the bond.

#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 0
#         assert phm.balanceOf(accounts[1].address) == 100

#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         assert phm.balanceOf(accounts[1].address) == 100

#     def test_negative_roi_bond(contracts):
#         bonding = contracts["bonding"]
#         treasury = contracts["treasury"]
#         vault = contracts["vault"]
#         admin = contracts["admin"]
#         token = contracts["token"]
#         phm = contracts["phm"]
#         admin.enableDebugMode()
#         admin.addMultipleTokensToBondingList([token.address], {"from": accounts[0]})  
#         token._mint_for_testing(accounts[1], 500)
#         token.approve(treasury.address, 500, {"from": accounts[1]})  
#         admin.addMultipleTokensToBondingList(BONDS, {"from": accounts[0]})
#         admin.setBondingMultiplierFor(ONE_DAY, token.address, 0.5*10**18, {"from": accounts[0]}) # 50 % 
#         assert admin.bondingMultiplierFor(ONE_DAY, token.address) == 0.5*(10**18)
#         result = bonding.createBond(500, token.address, ONE_DAY, {"from": accounts[1]}) # 50 % 
#         # in the debug mode 5 token is 1 phm, 500 token is 100 phm but @ 50% discount == 200 phm
#         assert result.return_value == 50
#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 50

#         chain.sleep(24 * 60 * 60) # time travel to the end of the bond.

#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 0
#         assert phm.balanceOf(accounts[1].address) == 50

#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         assert phm.balanceOf(accounts[1].address) == 50

#     def test_basic_bonding_token_redeem_multi_times(contracts):
#         bonding = contracts["bonding"]
#         treasury = contracts["treasury"]
#         vault = contracts["vault"]
#         admin = contracts["admin"]
#         token = contracts["token"]
#         phm = contracts["phm"]
#         admin.enableDebugMode()
#         admin.addMultipleTokensToBondingList([token.address], {"from": accounts[0]})  
#         token._mint_for_testing(accounts[1], 500)
#         token.approve(treasury.address, 500, {"from": accounts[1]})  
#         admin.addMultipleTokensToBondingList(BONDS, {"from": accounts[0]})
#         admin.setBondingMultiplierFor(ONE_DAY, token.address, 2*10**18, {"from": accounts[0]}) # 50 % 
#         assert admin.bondingMultiplierFor(ONE_DAY, token.address) == 2*(10**18)
#         result = bonding.createBond(500, token.address, ONE_DAY, {"from": accounts[1]}) # 50 % 
#         # in the debug mode 5 token is 1 phm, 500 token is 100 phm but @ 50% discount == 200 phm
#         assert result.return_value == 200
#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 200

#         chain.sleep(12 * 60 * 60) # time travel to the midaway point of the bond.

#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 100
#         assert phm.balanceOf(accounts[1].address) == 100

#         chain.sleep(6 * 60 * 60) # time travel to the 3/4's point of the bond.

#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 50
#         assert phm.balanceOf(accounts[1].address) == 150

#         chain.sleep(6 * 60 * 60) # time travel to the end point of the bond.

#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         assert token.balanceOf(vault.address) == 500
#         assert phm.balanceOf(vault.address) == 0
#         assert phm.balanceOf(accounts[1].address) == 200

#     def test_multiple_bonds_different_lengths(contracts):
#         bonding = contracts["bonding"]
#         treasury = contracts["treasury"]
#         vault = contracts["vault"]
#         admin = contracts["admin"]

#         token = contracts["token"]
#         token._mint_for_testing(accounts[1], 30*10**18)
#         token.approve(treasury.address, 30*10**18, {"from": accounts[1]})  

#         token2 = contracts["token2"]
#         token2._mint_for_testing(accounts[1], 30*10**18)
#         token2.approve(treasury.address, 30*10**18, {"from": accounts[1]})  

#         token3 = contracts["token3"]
#         token3._mint_for_testing(accounts[1], 30*10**13)
#         token3.approve(treasury.address, 30*10**13, {"from": accounts[1]})  

#         token4 = contracts["token4"]
#         token4._mint_for_testing(accounts[1], 30*10**13)
#         token4.approve(treasury.address, 30*10**13, {"from": accounts[1]})  
#         phm = contracts["phm"]
#         admin.enableDebugMode()
#         admin.addMultipleTokensToBondingList([token.address, token2.address, token3.address, token4.address], {"from": accounts[0]})
#         admin.setBondingMultiplierFor(ONE_DAY, token.address, 1.25*(10**18), {"from": accounts[0]})
#         assert admin.bondingMultiplierFor(ONE_DAY, token.address) == 1.25*(10**18)
#         admin.setBondingMultiplierFor(THREE_DAY, token.address, 2*(10**18), {"from": accounts[0]}) 
#         admin.setBondingMultiplierFor(THREE_DAY, token2.address, 3*(10**18), {"from": accounts[0]}) 
#         admin.setBondingMultiplierFor(FIVE_DAY, token2.address, 4*(10**18), {"from": accounts[0]})
#         admin.setBondingMultiplierFor(THREE_DAY, token3.address, 2*(10**18), {"from": accounts[0]}) 
#         admin.setBondingMultiplierFor(FIVE_DAY, token3.address, 1.25*(10**18), {"from": accounts[0]})
#         admin.setBondingMultiplierFor(FIVE_DAY, token3.address, 2*(10**18), {"from": accounts[0]})
#         admin.setBondingMultiplierFor(ONE_DAY, token4.address, 2.5*(10**18), {"from": accounts[0]})
#         admin.setBondingMultiplierFor(FIVE_DAY, token4.address, 6*(10**18), {"from": accounts[0]})

#         # bond 0
#         result = bonding.createBond(3 * 10**18, token.address, ONE_DAY, {"from": accounts[1]}).return_value 
#         assert result == 3*10**18 * 1.25/5
#         # bond 1
#         result = bonding.createBond(12 * 10**18, token2.address, THREE_DAY, {"from": accounts[1]}).return_value
#         assert result == 12*10**18 * 3/5

#         chain.sleep(12 * 60 * 60) # ff 12 hours
#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         assert abs(phm.balanceOf(accounts[1])- ((3*10**18 * 1.25/5)/2.0 + (12*10**18 * 3/5)/6.0)) < ACCEPTABLE_TIMING_ERROR
#         # bond 2
#         result = bonding.createBond(7 * 10**18, token.address, THREE_DAY, {"from": accounts[1]}).return_value
#         assert result == 7*10**18 * 2/5
#         # bond 3
#         result = bonding.createBond(12 * 10**18, token2.address, THREE_DAY, {"from": accounts[1]}).return_value
#         assert result == 12*10**18 * 3/5
#         # bond 4
#         result = bonding.createBond(12 * 10**13, token3.address, THREE_DAY, {"from": accounts[1]}).return_value
#         assert result == 12*10**18 * 2/5

#         chain.sleep(12 * 60 * 60) # ff 12 hoursS
#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         # bond 0 has fully vested, bond 1 is 1/3, bond 2 is 1/6 bond 3 is 1/6 bond 4 is 1/6
#         assert abs(phm.balanceOf(accounts[1]) - ((3*10**18 * 1.25/5) + (12*10**18 * 3/5)/3 + (7*10**18 * 2/5)/6 + (12*10**18 * 3/5)/6 + (12*10**18 * 2/5)/6)) < ACCEPTABLE_TIMING_ERROR

#         # bond 5
#         result = bonding.createBond(12 * 10**13, token4.address, FIVE_DAY, {"from": accounts[1]}).return_value
#         assert result == 12*10**18 * 6/5

#         chain.sleep(10 * 24 * 60 * 60) # ff 10 days

#         bonding.redeemBonds(False, {"from": accounts[1]}) # no autostake

#         # everything vested
#         assert abs(phm.balanceOf(accounts[1]) - ((3*10**18 * 1.25/5) + (12*10**18 * 3/5) + (7*10**18 * 2/5) + (12*10**18 * 3/5) + (12*10**18 * 2/5) +(12*10**18 * 6/5))) < ACCEPTABLE_TIMING_ERROR