def test_donate(contracts, accounts):
    vault = contracts["vault"]
    treasury = contracts["treasury"]
    finance = contracts["finance"]
    best_friend = accounts[1]
    token = contracts['token']

    token._mint_for_testing(best_friend.address, 1000e18)
    token.approve(treasury.address, token.balanceOf(best_friend.address), {"from": best_friend})
    assert token.balanceOf(best_friend.address) == 1000e18
    finance.donate(1000e18, token.address, {"from": best_friend})
    assert token.balanceOf(best_friend.address) == 0
    assert token.balanceOf(vault.address) == 1000e18