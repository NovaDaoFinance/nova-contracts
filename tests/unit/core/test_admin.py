import brownie


def test_guard(contracts, accounts):
    admin = contracts["admin"]
    guard = contracts["guard"]
    developer = contracts["developer"]

    admin.updateStakingRewardRate(1e15, {"from": developer})

    admin.setOwner(accounts[1].address)
    with brownie.reverts('ds-auth-unauthorized'):
        admin.updateStakingRewardRate(1e15, {"from": developer})

    guard.permit['address,address,bytes4'](developer.address, admin.address, admin.updateStakingRewardRate.signature)
    admin.updateStakingRewardRate(1e15, {"from": developer})