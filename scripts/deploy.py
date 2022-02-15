from brownie import *

from .contract_addresses import CONTRACTS
from .utils import TEN18, fetch_storage_contract, is_deployed, publish, set_deployed_status


COMMITTEE_MULTISIG = '0x5DfeDb20C722a9D4529B2B0948a3CE526BB6Fe90'
POLICY_MULTISIG = '0xbFf2300aD0B40149Fdf847239408FACF95F7B43C'
OPERATIONS_MULTISIG = '0x1aC0a53aDf09E0e4264DD2cA636282DFce44e4BF'
ACCELERATOR_MULTISIG = '0x8f7A3E1788f179D2bFc74dDE083bB0DDdb24ab51'


def main(account):
    acct = accounts.load(account)

    # Storage contract
    storage = deploy_storage(acct)
    CONTRACTS[network.show_active()]['PhantomStorage'] = storage.address  # Used for all other deploys

    #########
    # Core contracts
    #########
    # Vault
    deploy_vault(acct)

    # Treasury
    deploy_treasury(acct)
    
    # Protocol Tokens
    deploy_phm(acct)
    deploy_sphm(acct)
    deploy_gphm(acct)
    deploy_aphm(acct)
    deploy_fphm(acct)

    # guard
    deploy_guard(acct)

    # Admin
    deploy_admin(acct)

    #########
    # Level 0 contracts
    #########
    # Staking
    deploy_staking(acct)

    # Bonding
    deploy_bonding(acct)

    # Executor
    deploy_executor(acct)

    # Finance
    deploy_dex_router(acct)
    # deploy_yearn_router(acct)
    #deploy_allocator(acct)
    #deploy_payments(acct)

    # AlphaSwap
    deploy_alphaswap(acct)

    # Founders
    deploy_founders(acct)

    # Dutch Auction Claim
    deploy_da_claim(acct)

    #########

    #########
    # Level 1 contracts
    #########
    # Governance
    deploy_governace(acct)

    # Finance
    deploy_finance(acct)

    # Launch
    deploy_launch(acct)

    # Set as deployed, revoking access from the account that has done the deployment
    # This isn't reversible, BE VERY CAREFUL. After this, acct can no long make any 
    # changes to the contracts (like minting coins).
    if set_deployed_status() and False:
        storage.setDeployedStatus()


def deploy_storage(acct):
    if is_deployed('PhantomStorage'):
        return fetch_storage_contract()
    else:
        return PhantomStorage.deploy({"from": acct}, publish_source=publish())


def deploy_vault(acct):
    if is_deployed('PhantomVault'):
        return PhantomVault.at(CONTRACTS[network.show_active()]['PhantomVault'])
    else:
        storage = fetch_storage_contract()
        vault = PhantomVault.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.vault", vault.address, {"from": acct})
        return vault


def deploy_phm(acct):
    if is_deployed('PHM'):
        return PHM.at(CONTRACTS[network.show_active()]['PHM'])
    else:
        storage = fetch_storage_contract()
        phm = PHM.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.phm", phm.address, {"from": acct})
        return phm


def deploy_sphm(acct):
    if is_deployed('sPHM'):
        return sPHM.at(CONTRACTS[network.show_active()]['sPHM'])
    else:
        storage = fetch_storage_contract()
        sphm = sPHM.deploy(storage.address, 1095, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.sphm", sphm.address, {"from": acct})
        return sphm


def deploy_gphm(acct):
    if is_deployed('gPHM'):
        return gPHM.at(CONTRACTS[network.show_active()]['gPHM'])
    else:
        storage = fetch_storage_contract()
        gphm = gPHM.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.gphm", gphm.address, {"from": acct})
        return gphm


def deploy_aphm(acct):
    if is_deployed('aPHM'):
        return aPHM.at(CONTRACTS[network.show_active()]['aPHM'])
    else:
        storage = fetch_storage_contract()
        aphm = aPHM.deploy(storage.address, 31428825119477670020000, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.aphm", aphm.address, {"from": acct})
        return aphm


def deploy_fphm(acct):
    if is_deployed('fPHM'):
        return fPHM.at(CONTRACTS[network.show_active()]['fPHM'])
    else:
        storage = fetch_storage_contract()
        fphm = fPHM.deploy(storage.address, 55435*TEN18, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.fphm", fphm.address, {"from": acct})
        return fphm


def deploy_treasury(acct):
    if is_deployed('PhantomTreasury'):
        return PhantomTreasury.at(CONTRACTS[network.show_active()]['PhantomTreasury'])
    else:
        storage = fetch_storage_contract()
        treasury = PhantomTreasury.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.treasury", treasury.address, {"from": acct})
        treasury.registerReserveToken('', {"from": acct})
        return treasury


def deploy_guard(acct):
    if is_deployed('PhantomGuard'):
        return PhantomGuard.at(CONTRACTS[network.show_active()]['PhantomGuard'])
    else:
        storage = fetch_storage_contract()
        guard = PhantomGuard.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.guard", guard.address, {"from": acct})

        return guard


def deploy_admin(acct):
    if is_deployed('PhantomAdmin'):
        return PhantomAdmin.at(CONTRACTS[network.show_active()]['PhantomAdmin'])
    else:
        assert is_deployed('PhantomGuard'), "Must deploy PhantomGuard first"
        storage = fetch_storage_contract()
        admin = PhantomAdmin.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.admin", admin.address, {"from": acct})

        # Setup method protections
        guard = PhantomGuard.at(CONTRACTS[network.show_active()]['PhantomGuard'])
        admin.setAuthority(guard.address, {"from": acct})
        if publish():
            # Policy Committee
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.updateStakingRewardRate.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.addTokenToBondingList.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.addMultipleTokensToBondingList.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.removeTokenFromBondingList.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.removeMultipleTokensToBondingList.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.setDebtLimit.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.addBondType.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.removeBondType.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.setBondingMultiplierFor.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.setSpiritAsDefaultDex.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.setSpookyAsDefaultDex.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.setCustomDefaultDex.signature,
                {"from": acct},
            )
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.rebalanceReserveTokens.signature,
                {"from": acct},
            )

            # Ops committee
            guard.permit['address','address','bytes4'](
                POLICY_MULTISIG, 
                admin.address, 
                admin.withdrawOpsDAOFunds.signature,
                {"from": acct},
            )
        else:
            guard.permit['bytes32','bytes32','bytes32'](
                guard.ANY(), 
                guard.ANY(), 
                guard.ANY(), 
                {"from": acct},
            )

        return admin


def deploy_staking(acct):
    if is_deployed('PhantomStaking'):
        return PhantomStaking.at(CONTRACTS[network.show_active()]['PhantomStaking'])
    else:
        storage = fetch_storage_contract()
        staking = PhantomStaking.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.staking", staking.address, {"from": acct})
        return staking


def deploy_bonding(acct):
    if is_deployed('PhantomBonding'):
        return PhantomBonding.at(CONTRACTS[network.show_active()]['PhantomBonding'])
    else:
        storage = fetch_storage_contract()
        bonding = PhantomBonding.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.bonding", bonding.address, {"from": acct})
        return bonding


def deploy_executor(acct):
    if is_deployed('PhantomExecutor'):
        return PhantomExecutor.at(CONTRACTS[network.show_active()]['PhantomExecutor'])
    else:
        storage = fetch_storage_contract()
        executor = PhantomExecutor.deploy(
            storage.address, 
            60*5, 
            [], 
            ['0x0000000000000000000000000000000000000000'], 
            {"from": acct}, 
            publish_source=publish()
        )
        storage.registerContract(b"phantom.contracts.executor", executor.address, {"from": acct})
        CONTRACTS[network.show_active()]['PhantomExecutor'] = executor.address
        return executor


def deploy_dex_router(acct):
    if is_deployed('PhantomDexRouter'):
        return PhantomDexRouter.at(CONTRACTS[network.show_active()]['PhantomDexRouter'])
    else:
        storage = fetch_storage_contract()
        router = PhantomDexRouter.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.dex_router", router.address, {"from": acct})
        return router


def deploy_allocator(acct):
    if is_deployed('PhantomAllocator'):
        return PhantomAllocator.at(CONTRACTS[network.show_active()]['PhantomAllocator'])
    else:
        storage = fetch_storage_contract()
        allocator = PhantomAllocator.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.allocator", allocator.address, {"from": acct})
        return allocator


def deploy_payments(acct):
    if is_deployed('PhantomPayments'):
        return PhantomPayments.at(CONTRACTS[network.show_active()]['PhantomPayments'])
    else:
        storage = fetch_storage_contract()
        payments = PhantomPayments.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.payments", payments.address, {"from": acct})
        return payments


def deploy_alphaswap(acct):
    if is_deployed('PhantomAlphaSwap'):
        return PhantomAlphaSwap.at(CONTRACTS[network.show_active()]['PhantomAlphaSwap'])
    else:
        storage = fetch_storage_contract()
        alpahswap = PhantomAlphaSwap.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.alphaswap", alpahswap.address, {"from": acct})
        return alpahswap


def deploy_founders(acct):
    if is_deployed('PhantomFounders'):
        return PhantomFounders.at(CONTRACTS[network.show_active()]['PhantomFounders'])
    else:
        storage = fetch_storage_contract()
        founders = PhantomFounders.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.founders", founders.address, {"from": acct})
        return founders


def deploy_da_claim(acct):
    token = '0xdc301622e621166bd8e82f2ca0a26c13ad0be355' if publish() else '0xd73c5eCa030f6FF6b46fAa727621087D36FDe23f'
    if is_deployed('PhantomAuctionClaim'):
        return PhantomAuctionClaim.at(CONTRACTS[network.show_active()]['PhantomAuctionClaim'])
    else:
        storage = fetch_storage_contract()
        auction_claim = PhantomAuctionClaim.deploy(storage.address, token, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.auctionclaim",auction_claim.address, {"from": acct})
        return auction_claim


def deploy_governace(acct):
    if is_deployed('PhantomGovernor'):
        return PhantomGovernor.at(CONTRACTS[network.show_active()]['PhantomGovernor'])
    else:
        assert is_deployed('gPHM'), "Must deploy gPHM first"
        assert is_deployed('PhantomExecutor'), "Must deploy PhantomExecutor first"
        gphm = gPHM.at(CONTRACTS[network.show_active()]['gPHM'])
        executor = PhantomExecutor.at(CONTRACTS[network.show_active()]['PhantomExecutor'])
        storage = fetch_storage_contract()
        governance= PhantomGovernor.deploy(
            storage.address, gphm, executor, 5, 48*60*60, 0, 10e18, 
            {"from": acct}, publish_source=publish()
        )
        storage.registerContract(b"phantom.contracts.governance", governance.address, {"from": acct})
        executor.grantRole(executor.EXECUTOR_ROLE(), governance.address, {"from": acct})
        executor.grantRole(executor.PROPOSER_ROLE(), governance.address, {"from": acct})
        return governance


def deploy_finance(acct):
    if is_deployed('PhantomFinance'):
        return PhantomFinance.at(CONTRACTS[network.show_active()]['PhantomFinance'])
    else:
        storage = fetch_storage_contract()
        finance = PhantomFinance.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.finance", finance.address, {"from": acct})
        return finance


def deploy_launch(acct):
    if is_deployed('PhantomLaunch'):
        return PhantomLaunch.at(CONTRACTS[network.show_active()]['PhantomLaunch'])
    else:
        storage = fetch_storage_contract()
        launch = PhantomLaunch.deploy(storage.address, {"from": acct}, publish_source=publish())
        storage.registerContract(b"phantom.contracts.launch", launch.address, {"from": acct})
        return launch

