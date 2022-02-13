import pytest
from brownie import exceptions
from web3 import Web3

NULL_ADDR = "0x0000000000000000000000000000000000000000"
ACCOUNT_KEYS = [
    Web3.keccak(text="phantom.treasury.account_keys.reserves"),
    Web3.keccak(text="phantom.treasury.account_keys.venturecapital"),
]
ACCOUNT_PERCENTAGES = [int(9e17), int(1e17),]
DAO_KEYS = [Web3.keccak(text="phantom.treasury.account_key.dao"),]
DAO_PERCENTAGES = [int(1e18),]


@pytest.fixture(autouse=True)
def router(contracts, DexRouterMock):
    storage = contracts["storage"]
    developer = contracts["developer"]
    router = DexRouterMock.deploy(storage.address, {"from": developer})
    storage.registerContract(b"phantom.contracts.dex_router", router.address, {"from": developer})


@pytest.fixture(autouse=True)
def isolation(module_isolation):
    '''Remove the mock dex deploy once the module is done'''
    pass


def test_swap(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    token = contracts["token"]
    token2 = contracts["token2"]
    storage = contracts["storage"]
    developer = contracts["developer"]
    token._mint_for_testing(accounts[1], 1000000000)
    token2._mint_for_testing(vault.address, 5000000000)

    token.approve(treasury.address, 1000000000, {"from": accounts[1]})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token2.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(4500000000), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token2.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(500000000), {"from": developer})
    treasury.swap(
        accounts[1], 1000000000, token.address, 5000, token2.address, 
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES,
        {"from": developer}
    )
    assert token.balanceOf(accounts[1]) == 0
    assert token2.balanceOf(accounts[1]) == 5000
    assert token.balanceOf(vault.address) == 1000000000
    assert token2.balanceOf(vault.address) == 4999995000

    with pytest.raises(exceptions.VirtualMachineError):
        treasury.swap(
            accounts[1], 1000000000, token.address, 5000, token2.address, 
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES,
            {"from": accounts[1]}
        )


def test_swap_burn(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    phm = contracts["phm"]
    token = contracts["token"]
    storage = contracts["storage"]
    developer = contracts["developer"]
    token._mint_for_testing(vault.address, 5000)
    token._mint_for_testing(accounts[1], 5000)
    phm.mint(vault.address, 45000000000)  # Get around max ownership rule
    phm.mint(accounts[1], 500000000)

    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(4500), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(500), {"from": developer})
    phm.approve(treasury.address, 100000000, {"from": accounts[1]})
    treasury.swapBurn(
        accounts[1], 100000000, phm.address, 5000, token.address, 
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES,
        {"from": developer}
    )
    assert phm.balanceOf(accounts[1]) == 400000000
    assert phm.totalSupply() == 400000000 + phm.balanceOf(vault.address)
    assert token.balanceOf(accounts[1]) == 10000
    assert token.balanceOf(vault.address) == 0

    # Not a registered controct
    token.approve(treasury.address, 5000, {"from": accounts[1]})
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.swapBurn(
            accounts[1], 500, phm.address, 5000, token.address, 
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES,
            {"from": accounts[1]}
        )

    # Not burning a phm token
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.swapBurn(
            accounts[1], 5000, token.address, 5000, phm.address, 
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES,
            {"from": developer}
        )


def test_swap_mint(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    developer = contracts["developer"]
    phm = contracts["phm"]
    token = contracts["token"]
    token._mint_for_testing(accounts[1], 1000000000)
    phm.mint(vault.address, 45000000000)  # Get around max ownership rule

    token.approve(treasury.address, 1000000000, {"from": accounts[1]})
    treasury.swapMint(
        accounts[1], 1000000000, token.address, 5000, phm.address, 
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES,
        {"from": developer}
    )
    assert token.balanceOf(accounts[1]) == 0
    assert phm.balanceOf(accounts[1]) == 5000
    assert token.balanceOf(vault.address) == 1000000000
    assert phm.balanceOf(vault.address) == 45000000000

    # Not a registered contract
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.swapMint(
            accounts[1], 1000000000, token.address, 5000, phm.address, 
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES,
            {"from": accounts[1]}
        )

    # Not a phm token being minted
    phm.mint(accounts[1], 500000000)
    phm.approve(treasury.address, 100000000, {"from": accounts[1]})
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.swapMint(
            accounts[1], 100000000, phm.address, 5000, token.address, 
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES,
            {"from": developer}
        )


def test_swap_burn_mint(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    developer = contracts["developer"]
    phm = contracts["phm"]
    token = contracts["token"]
    token2 = contracts["token2"]
    token._mint_for_testing(accounts[1], 1000000000)
    phm.mint(vault.address, 45000000000)  # Get around max ownership rule

    token.approve(treasury.address, 1000000000, {"from": accounts[1]})
    treasury.swapBurnMint(
        accounts[1], 1000000000, token.address, 5000, phm.address, 
        {"from": developer}
    )
    assert token.balanceOf(accounts[1]) == 0
    assert phm.balanceOf(accounts[1]) == 5000
    assert token.balanceOf(vault.address) == 0

    # Not a registered contract
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.swapBurnMint(
            accounts[1], 1000000000, token.address, 5000, phm.address, 
            {"from": accounts[1]}
        )

    # Not a phm token being minted
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.swapBurnMint(
            accounts[1], 1000000000, token.address, 5000, token2.address, 
            {"from": developer}
        )


def test_deposit(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    token = contracts["token"]
    phm = contracts["phm"]
    developer = contracts["developer"]
    storage = contracts["storage"]

    # Need a positive PHM balance for the excessReserves calc
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', phm.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(4500000000), {"from": developer})
    token._mint_for_testing(accounts[1], 1000000000)
    token.approve(treasury.address, 10000, {"from": accounts[1]})
    treasury.deposit(
        accounts[1], 1000, token.address,
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 
        1**16, 0,
        DAO_KEYS, DAO_PERCENTAGES, 
        {"from": developer}
    )
    # 1000 of token is 200 phm (amount/5)
    assert phm.balanceOf(vault.address) == 1000/5*1**16
    assert token.balanceOf(vault.address) == 1000
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.deposit(
            accounts[1], 1000, token.address,
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 
            10**18, 1**18,
            DAO_KEYS, DAO_PERCENTAGES, 
            {"from": accounts[1]}
        )


def test_deposit_positive_mint_ratio(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    token = contracts["token"]
    phm = contracts["phm"]
    developer = contracts["developer"]

    token._mint_for_testing(accounts[1], 1000000000)
    token.approve(treasury.address, 10000, {"from": accounts[1]})
    treasury.deposit(
        accounts[1], 1000, token.address,
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 
        1.5*10**18, 0,
        DAO_KEYS, DAO_PERCENTAGES, 
        {"from": developer}
    )
    # 1000 of token is 200 phm (amount/5)
    assert phm.balanceOf(vault.address) == 1000/5*1.5*10**18
    assert token.balanceOf(vault.address) == 1000


def test_deposit_negative_mint_ratio(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    token = contracts["token"]
    phm = contracts["phm"]
    developer = contracts["developer"]

    token._mint_for_testing(accounts[1], 1000000000)
    token.approve(treasury.address, 10000, {"from": accounts[1]})
    treasury.deposit(
        accounts[1], 1000, token.address,
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 
        0.75*10**18, 0,
        DAO_KEYS, DAO_PERCENTAGES, 
        {"from": developer}
    )
    # 1000 of token is 200 phm (amount/5)
    assert phm.balanceOf(vault.address) == 1000/5*0.75*10**18
    assert token.balanceOf(vault.address) == 1000


def test_deposit_profit_ratio(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    token = contracts["token"]
    phm = contracts["phm"]
    developer = contracts["developer"]

    token._mint_for_testing(accounts[1], 1000000000)
    token.approve(treasury.address, 10000, {"from": accounts[1]})
    treasury.deposit(
        accounts[1], 1000, token.address,
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 
        10**18, 10**17,
        DAO_KEYS, DAO_PERCENTAGES, 
        {"from": developer}
    )
    # 1000 of token is 200 phm (amount/5)
    assert phm.balanceOf(vault.address) == 1000/5*10**18+1000/5*10**18*0.1
    assert token.balanceOf(vault.address) == 1000


def test_deposit_mixed_decimals(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    token2 = contracts["token2"]
    phm = contracts["phm"]
    developer = contracts["developer"]

    token2._mint_for_testing(accounts[1], 1000 * (10**token2.decimals()))
    token2.approve(treasury.address, 1000 * (10**token2.decimals()), {"from": accounts[1]})
    treasury.deposit(
        accounts[1], 1000 * (10**token2.decimals()), token2.address,
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 
        0.9*10**18, 0,
        DAO_KEYS, DAO_PERCENTAGES, 
        {"from": developer}
    )
    # 1000 of token is 200 phm (amount/5)
    assert phm.balanceOf(vault.address) == 1000 / 5 * 0.9*10**18 * (10**phm.decimals())
    assert token2.balanceOf(vault.address) == 1000 * (10**token2.decimals())


def test_withdraw(contracts, accounts):
    treasury = contracts["treasury"]
    vault = contracts["vault"]
    token = contracts["token"]
    developer = contracts["developer"]
    storage = contracts["storage"]
    phm = contracts["phm"]

    phm.mint(vault.address, 200)
    token._mint_for_testing(vault.address, 1000)
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', phm.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(200*.9), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', phm.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(200*.1), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(1000*.9), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(1000*.1), {"from": developer})
    assert phm.balanceOf(vault.address) == 200
    assert token.balanceOf(vault.address) == 1000

    phm.approve(treasury.address, 10000, {"from": accounts[1]})
    treasury.withdraw(
        accounts[1], 1000, token.address, 
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 1, 
        {"from": developer}
    )

    # 1000 of token is 200 phm (amount/5)
    assert phm.balanceOf(vault.address) == 0
    assert token.balanceOf(vault.address) == 0
    assert token.balanceOf(accounts[1].address ) == 1000
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.withdraw(
            accounts[1], 1000, token.address, 
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 10**18, 
            {"from": accounts[1]}
        )


def test_withdraw_positive_burn_ratio(contracts, accounts):
    treasury = contracts["treasury"]
    developer = contracts["developer"]
    storage = contracts["storage"]
    vault = contracts["vault"]
    token = contracts["token"]
    phm = contracts["phm"]

    phm.mint(vault.address, 300e18)
    token._mint_for_testing(vault.address, 1000)
    assert phm.balanceOf(vault.address) == 300e18
    assert token.balanceOf(vault.address) == 1000
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', phm.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(300e18*.9), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', phm.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(300e18*.1), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(1000*.9), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(1000*.1), {"from": developer})

    phm.approve(treasury.address, 10000, {"from": accounts[1]})
    treasury.withdraw(
        accounts[1], 1000, token.address, 
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 1.5e18, 
        {"from": developer}
    )
    # 1000 of token is 200 phm (amount/5)
    assert phm.balanceOf(vault.address) == 0
    assert token.balanceOf(vault.address) == 0
    assert token.balanceOf(accounts[1].address ) == 1000
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.withdraw(
            accounts[1], 1000, token.address, 
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 1.5*10**18, 
            {"from": accounts[1]}
        )


def test_withdraw_negative_burn_ratio(contracts, accounts):
    treasury = contracts["treasury"]
    developer = contracts["developer"]
    storage = contracts["storage"]
    vault = contracts["vault"]
    token = contracts["token"]
    phm = contracts["phm"]

    phm.mint(vault.address, 200e18)
    token._mint_for_testing(vault.address, 1000)
    assert phm.balanceOf(vault.address) == 200e18
    assert token.balanceOf(vault.address) == 1000
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', phm.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(200e18*.9), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', phm.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(200e18*.1), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(1000*.9), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(1000*.1), {"from": developer})

    phm.approve(treasury.address, 10000, {"from": accounts[1]})
    treasury.withdraw(
        accounts[1], 1000, token.address, 
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 0.8e18, 
        {"from": developer}
    )

    # 1000 of token is 200 phm (amount/5)
    assert phm.balanceOf(vault.address) == 40e18
    assert token.balanceOf(vault.address) == 0
    assert token.balanceOf(accounts[1].address ) == 1000
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.withdraw(
            accounts[1], 1000, token.address, 
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 0.8e18, 
            {"from": accounts[1]}
        )


def test_withdraw_mixed_decimals(contracts, accounts):
    treasury = contracts["treasury"]
    developer = contracts["developer"]
    storage = contracts["storage"]
    vault = contracts["vault"]
    token2 = contracts["token"]
    phm = contracts["phm"]

    phm.mint(vault.address, 200e18)
    token2._mint_for_testing(vault.address, 1000)
    assert phm.balanceOf(vault.address) == 200e18
    assert token2.balanceOf(vault.address) == 1000
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', phm.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(200e18*.9), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', phm.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(200e18*.1), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token2.address, Web3.keccak(b'phantom.treasury.account_keys.reserves')]
    ), int(1000*.9), {"from": developer})
    storage.setUint(Web3.solidityKeccak(
        ['bytes', 'address', 'bytes'], 
        [b'phantom.treasury.balances', token2.address, Web3.keccak(b'phantom.treasury.account_keys.venturecapital')]
    ), int(1000*.1), {"from": developer})

    phm.approve(treasury.address, 10000, {"from": accounts[1]})
    treasury.withdraw(
        accounts[1], 1000, token2.address, 
        ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 0.4e18, 
        {"from": developer}
    )

    # 1000 of token is 200 phm (amount/5)
    assert phm.balanceOf(vault.address) == 120e18
    assert token2.balanceOf(vault.address) == 0
    assert token2.balanceOf(accounts[1].address ) == 1000
    with pytest.raises(exceptions.VirtualMachineError):
        treasury.withdraw(
            accounts[1], 1000, token2.address, 
            ACCOUNT_KEYS, ACCOUNT_PERCENTAGES, 0.4e18, 
            {"from": developer}
        )