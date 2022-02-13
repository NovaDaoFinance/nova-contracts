import pytest

from eth_abi import encode_abi

ONE_DAY = b"one_day_bond"
THREE_DAY = b"three_day_bond"
FIVE_DAY = b"five_day_bond"


@pytest.fixture()
def dao_developer(accounts):
    return accounts[0]

@pytest.fixture()
def phantom_storage(PhantomStorage, dao_developer):
    phantom_storage = PhantomStorage.deploy({'from': dao_developer})
    phantom_storage.registerContract(b'dev', dao_developer.address, {'from': dao_developer})
    return phantom_storage


@pytest.fixture()
def contracts(
    accounts, PhantomStorage, ERC20Mock, PhantomAdmin, PhantomVault, PhantomTreasury,
    PhantomStaking, PhantomBonding, PhantomDutchAuctionVault, PhantomAlphaSwap, 
    PhantomFounders, PHM, sPHM, gPHM, fPHM, aPHM, ERC20MockWeirdDecimals, PhantomFinance,
    PhantomGovernor, PhantomExecutor, PhantomGuard, PhantomAuctionClaim, BondPricingMock,
):
    # Storage
    storage = PhantomStorage.deploy({"from": accounts[0]})

    # Vault
    vault = PhantomVault.deploy(storage.address, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.vault", vault.address, {"from": accounts[0]})
    
    # Treasury
    treasury = PhantomTreasury.deploy(storage.address, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.treasury", treasury.address, {"from": accounts[0]})

    # Protocol Tokens
    phm = PHM.deploy(storage.address, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.phm", phm.address, {"from": accounts[0]})
    sphm = sPHM.deploy(storage.address, 1095, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.sphm", sphm.address, {"from": accounts[0]})
    gphm = gPHM.deploy(storage.address, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.gphm", gphm.address, {"from": accounts[0]})
    fphm = fPHM.deploy(storage.address, 2500*10**18, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.fphm", fphm.address, {"from": accounts[0]})
    aphm = aPHM.deploy(storage.address, 7500*10**18, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.aphm", aphm.address, {"from": accounts[0]})

    # Test Tokens
    token = ERC20Mock.deploy("Token0", "TK0", {"from": accounts[0]})
    token.approve(treasury.address, 10**50, {"from": accounts[0]})
    token2 = ERC20Mock.deploy("Token2", "TK2", {"from": accounts[0]})
    token2.approve(treasury.address, 10**50, {"from": accounts[0]})
    token3 = ERC20MockWeirdDecimals.deploy("Token3", "TK3", {"from": accounts[0]})
    token3.approve(treasury.address, 10**50, {"from": accounts[0]})
    token4 = ERC20MockWeirdDecimals.deploy("Token4", "TK4", {"from": accounts[0]})
    token4.approve(treasury.address, 10**50, {"from": accounts[0]})

    treasury.registerReserveToken(token.address, {"from": accounts[0]})
    treasury.registerReserveToken(token2.address, {"from": accounts[0]})
    treasury.registerReserveToken(token3.address, {"from": accounts[0]})
    treasury.registerReserveToken(token4.address, {"from": accounts[0]})

    # Guard
    guard = PhantomGuard.deploy(storage.address, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.guard", guard.address, {"from": accounts[0]})

    # Admin
    admin = PhantomAdmin.deploy(storage.address, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.admin", admin.address, {"from": accounts[0]})
    admin.setAuthority(guard, {"from": accounts[0]})

    # Staking
    staking = PhantomStaking.deploy(storage.address, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.staking", staking.address, {"from": accounts[0]})

    # Bonding
    bonding = PhantomBonding.deploy(storage.address, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.bonding", bonding.address, {"from": accounts[0]})

    bonds = [x.address for x in [token, token2]]

    admin.addBondType(ONE_DAY, 24*60*60, {"from": accounts[0]})
    admin.addBondType(THREE_DAY, 3*24*60*60, {"from": accounts[0]})
    admin.addBondType(FIVE_DAY, 5*24*60*60, {"from": accounts[0]})
    admin.addMultipleTokensToBondingList(bonds, {"from": accounts[0]})
    # Just use dummy tokens. Thins mock ignores the token addresses
    bondpricing = BondPricingMock.deploy({"from": accounts[0]})
    # Register a range of differe BondPricinging mocks based on bonds.
    admin.registerBondPricingTWAP(bondpricing, token.address)
    admin.registerBondPricingTWAP(bondpricing, token2.address)
    admin.registerBondPricingTWAP(bondpricing, token3.address)
    admin.registerBondPricingTWAP(bondpricing, token4.address)

    # Executor
    executor = PhantomExecutor.deploy(
        storage.address, 
        60*5, 
        [], 
        ['0x0000000000000000000000000000000000000000'], 
        {"from": accounts[0]}
    )
    storage.registerContract(b"phantom.contracts.executor", executor.address, {"from": accounts[0]})

    # Founders
    founders = PhantomFounders.deploy(storage.address, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.founders", founders.address, {"from": accounts[0]})
    
    # AlphaSwap 
    swap = PhantomAlphaSwap.deploy(storage.address, {"from": accounts[0]} )
    storage.registerContract(b"phantom.contracts.swap", swap.address, {"from": accounts[0]})

    # Finance 
    finance = PhantomFinance.deploy(storage.address, {"from": accounts[0]} )
    storage.registerContract(b"phantom.contracts.finance", finance.address, {"from": accounts[0]})

    # Governor 
    governor = PhantomGovernor.deploy(
        storage.address, gphm, executor, 5, 48*60*60, 0, 0, 
        {"from": accounts[0]}
    )
    storage.registerContract(b"phantom.contracts.governor", governor.address, {"from": accounts[0]})

    # DutchAuction
    auction  = PhantomDutchAuctionVault.deploy(storage.address, token4, {"from": accounts[0]})
    storage.registerContract(b"phantom.contracts.auction", auction.address, {"from": accounts[0]})

    # AuctionClaim 
    auctionclaim = PhantomAuctionClaim.deploy(storage.address, token, {"from": accounts[0]} )
    storage.registerContract(b"phantom.contracts.swap", auctionclaim.address, {"from": accounts[0]})

    return {
        "bonds": bonds, "bonding": bonding, "staking": staking, "sphm": sphm, "phm": phm, "gphm": gphm,
        "fphm": fphm, "aphm": aphm, "admin": admin, "token": token, "token2": token2, "token3": token3, 
        "token4": token4, "vault": vault, "storage": storage, "treasury": treasury, "developer": accounts[0], 
        "auction": auction, "swap": swap, "founders": founders, "finance": finance, "governor": governor,
        "executor": executor, "guard": guard, "auctionclaim": auctionclaim,
    }