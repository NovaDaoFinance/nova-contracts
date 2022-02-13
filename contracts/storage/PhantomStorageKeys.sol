/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title PhantomStorageKeys
 * @author PhantomDao Team
 * @notice Stores keys to use for lookup in the PhantomStorage() contract
 */
abstract contract PhantomStorageKeys {
    //=================================================================================================================
    // Declarations
    //=================================================================================================================

    _security internal security = _security("security.addressof", "security.name", "security.registered");

    _phantom internal phantom =
        _phantom(
            _contracts(
                "phantom.contracts.alphaswap",
                "phantom.contracts.founders",
                "phantom.contracts.staking",
                "phantom.contracts.stakingwarmup",
                "phantom.contracts.bonding",
                "phantom.contracts.phm",
                "phantom.contracts.sphm",
                "phantom.contracts.gphm",
                "phantom.contracts.aphm",
                "phantom.contracts.fphm",
                "phantom.contracts.vault",
                "phantom.contracts.treasury",
                "phantom.contracts.twap",
                "phantom.contracts.bondpricing",
                "phantom.contracts.dex_router",
                "phantom.contracts.yearn_router",
                "phantom.contracts.executor",
                "phantom.contracts.payments",
                "phantom.contracts.guard",
                "phantom.contracts.auctionclaim"
            ),
            _treasury(
                "phantom.treasury.approved.external.address",
                _treasuryaccounts(
                    "phantom.treasury.account_key.venturecapital",
                    "phantom.treasury.account_key.dao",
                    "phantom.treasury.account_key.reserves"
                ),
                "phantom.treasury.balances"
            ),
            _allocator(
                _tokens(
                    _token_addresses(
                        "phantom.allocator.tokens.address.dai",
                        "phantom.allocator.tokens.address.wftm",
                        "phantom.allocator.tokens.address.mim",
                        "phantom.allocator.tokens.address.dai_phm_lp",
                        "phantom.allocator.tokens.address.dex"
                    ),
                    "phantom.allocator.tokens.destinations",
                    "phantom.allocator.tokens.dest_percentages",
                    "phantom.allocator.tokens.lp",
                    "phantom.allocator.tokens.single"
                )
            ),
            _bonding(
                _bonding_user(
                    "phantom.bonding.user.first_unredeemed_nonce",
                    "phantom.bonding.user.lowest_assignable_nonce",
                    "phantom.bonding.user.lowest_nonce_still_vesting"
                ),
                "phantom.bonding.vestingblocks",
                "phantom.bonding.profit_ratio",
                "phantom.bonding.is_redeemed",
                "phantom.bonding.vests_at_timestamp",
                "phantom.bonding.is_valid",
                "phantom.bonding.multiplier",
                "phantom.bonding.debt",
                "phantom.bonding.max_debt_ratio",
                "phantom.bonding.remaining_payout_for",
                "phantom.bonding.token",
                "phantom.bonding.last_claim_at",
                "phantom.bonding.vest_length"
            ),
            _staking("phantom.staking.rebaseCounter", "phantom.staking.nextRebaseDeadline"),
            _founder(
                _founder_claims(
                    "phantom.founder.claims.allocation",
                    "phantom.founder.claims.initialAmount",
                    "phantom.founder.claims.remainingAmount",
                    "phantom.founder.claims.lastClaim"
                ),
                _founder_wallet_changes("phantom.founder.changes.newOwner"),
                "phantom.founder.vestingStarts"
            ),
            _routing(
                "phantom.routing.dex_router_address",
                "phantom.routing.dex_factory_address",
                "phantom.routing.spirit_router_address",
                "phantom.routing.spirit_factory_address",
                "phantom.routing.spooky_router_address",
                "phantom.routing.spooky_factory_address",
                "phantom.routing.spirit_gauge_address",
                "phantom.routing.spirit_gauge_proxy_address"
            ),
            _governor(
                "phantom.governor.votingDelay",
                "phantom.governor.votingPeriod",
                "phantom.governor.quorumPercentage",
                "phantom.governor.proposalThreshold"
            )
        );

    //=================================================================================================================
    // Definitions
    //=================================================================================================================

    struct _security {
        bytes addressof;
        bytes name;
        bytes registered;
    }

    struct _phantom {
        _contracts contracts;
        _treasury treasury;
        _allocator allocator;
        _bonding bonding;
        _staking staking;
        _founder founder;
        _routing routing;
        _governor governor;
    }

    struct _treasury {
        bytes approved_address;
        _treasuryaccounts account_keys;
        bytes balances;
    }

    struct _allocator {
        _tokens tokens;
    }

    struct _tokens {
        _token_addresses addresses;
        bytes destinations;
        bytes dest_percentage;
        bytes lp;
        bytes single;
    }

    struct _token_addresses {
        bytes dai;
        bytes wftm;
        bytes mim;
        bytes dai_phm_lp;
        bytes spirit;
    }

    struct _treasuryaccounts {
        bytes venturecapital;
        bytes dao;
        bytes reserves;
    }

    struct _vault {
        bytes something;
    }

    struct _routing {
        bytes dex_router_address;
        bytes dex_factory_address;
        bytes spirit_router_address;
        bytes spirit_factory_address;
        bytes spooky_router_address;
        bytes spooky_factory_address;
        bytes spirit_gauge_address;
        bytes spirit_gauge_proxy_address;
    }

    struct _bonding_user {
        bytes first_unredeemed_nonce;
        bytes lowest_assignable_nonce;
        bytes lowest_nonce_still_vesting;      
    }

    struct _bonding {
        _bonding_user user;
        bytes vestingblocks;
        bytes profit_ratio;
        bytes is_redeemed;
        bytes vests_at_timestamp;
        bytes is_valid;
        bytes multiplier;
        bytes debt;
        bytes max_debt_ratio;
        bytes remaining_payout_for;
        bytes token;
        bytes last_claim_at;
        bytes vest_length;
    }

    struct _staking {
        bytes rebaseCounter;
        bytes nextRebaseDeadline;
    }

    struct _founder {
        _founder_claims claims;
        _founder_wallet_changes changes;
        bytes vestingStarts;
    }

    struct _founder_claims {
        bytes allocation;
        bytes initialAmount;
        bytes remainingAmount;
        bytes lastClaim;
    }

    struct _founder_wallet_changes {
        bytes newOwner;
    }

    struct _contracts {
        bytes alphaswap;
        bytes founders;
        bytes staking;
        bytes stakingwarmup;
        bytes bonding;
        bytes phm;
        bytes sphm;
        bytes gphm;
        bytes aphm;
        bytes fphm;
        bytes vault;
        bytes treasury;
        bytes twap;
        bytes bondpricing;
        bytes dex_router;
        bytes yearn_router;
        bytes executor;
        bytes payments;
        bytes guard;
        bytes auctionclaim;
    }

    struct _governor {
        bytes votingDelay;
        bytes votingPeriod;
        bytes quorumPercentage;
        bytes proposalThreshold;
    }
}
