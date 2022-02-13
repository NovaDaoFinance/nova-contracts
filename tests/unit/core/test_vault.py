import pytest
from brownie import exceptions


def test_withdraw(contracts, accounts):
    vault = contracts['vault']
    developer = contracts['developer']
    token = contracts['token']

    token._mint_for_testing(accounts[0], 10)
    token._mint_for_testing(accounts[1], 10)
    token.transfer(vault.address, 10, {'from': developer})
    assert token.balanceOf(vault.address) == 10
    vault.withdraw(5, token.address, {'from': developer})
    assert token.balanceOf(vault.address) == 5

    with pytest.raises(exceptions.VirtualMachineError):
        vault.withdraw(10, token.address, {"from": accounts[1]})


def test_burn(contracts):
    vault = contracts['vault']
    developer = contracts['developer']
    token = contracts['token']

    token._mint_for_testing(developer, 10)
    token.transfer(vault.address, 10, {'from': developer})
    vault.burn(5, token.address, {'from': developer})
    assert token.balanceOf(vault, {'from': developer}) == 5


def test_deposit(contracts, accounts):
    token = contracts['token']
    vault = contracts['vault']

    token._mint_for_testing(accounts[0], 1000000000)
    assert token.balanceOf(accounts[0]) == 1000000000
    token.transfer(vault.address, 900000000, {"from": accounts[0]})
    assert token.balanceOf(vault.address) == 900000000
    assert token.balanceOf(accounts[0]) == 100000000
    token.approve(accounts[1].address, 3000, {"from": accounts[0]})
    token.transferFrom(accounts[0].address, vault.address, 3000, {"from": accounts[1]})
    assert token.balanceOf(vault.address) == 900003000