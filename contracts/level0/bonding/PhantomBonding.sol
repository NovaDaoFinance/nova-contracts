/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {PRBMathSD59x18} from "@hifi-finance/prb-math/contracts/PRBMathSD59x18.sol";
/* Package Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomBonding} from "../../../interfaces/level0/bonding/IPhantomBonding.sol";

/**
 * @title PhantomBonding
 * @author PhantomDao Team
 * @notice The contract that handles bonding assets to get PHM
 */
contract PhantomBonding is PhantomStorageMixin, IPhantomBonding {
    using PRBMathUD60x18 for uint256;

    constructor(address storageAddress) PhantomStorageMixin(storageAddress) {
        return;
    }

    //=================================================================================================================
    // Core Functions
    //=================================================================================================================

    function createBond(
        address inUser,
        uint256 inAmount,
        address inToken,
        bytes calldata inBondType
    ) external override nonReentrant returns (uint256) {
        if (!(isValidBond(inToken))) revert PhantomBondingError_IsNotValidBondingToken(inToken);
        uint256 mintRatio = uint256(bondingMultiplierFor(inToken, inBondType));
        uint256 rewardForDeposit = PhantomTreasury().deposit(
            inUser,
            inAmount,
            inToken,
            standardAccountKeys(),
            standardAccountPercentages(),
            mintRatio,
            bondProfitRatio(),
            daoKey(),
            percentage100()
        );
        if (!safeToBond(inUser, rewardForDeposit)) revert PhantomBondingError_ExceedsDebtLimit();
        uint256 nonce = lowestNonceAssignable(inUser);
        setTokenForBond(inUser, nonce, inToken);
        calculateAndSetVestingTimeForBond(inBondType, inUser, nonce);
        setPayoutForBond(inUser, nonce, rewardForDeposit);
        incrementLowestNonceAssignable(inUser);
        increaseOutstandingBondDebt(rewardForDeposit);
        emit PhantomBonding_BondCreated(inUser, rewardForDeposit, nonce);
        return rewardForDeposit;
    }

    function redeemBonds(address inUser, bool autoStake) external override nonReentrant returns (uint256) {
        uint256 toClaim;
        uint256 _lowestNonceAssignable = lowestNonceAssignable(inUser);
        uint256 nonceToClaimFrom = lowestNonceStillVesting(inUser);
        while (nonceToClaimFrom < _lowestNonceAssignable) {
            toClaim += claimFromBond(inUser, nonceToClaimFrom++);
        }
        if (autoStake) {
            PhantomTreasury().swapBurnMint(inUser, toClaim, address(PHM()), toClaim, address(sPHM()));
        } else {
            PhantomTreasury().swap(inUser, (0), address(0), toClaim, address(PHM()), reserveKey(), percentage100());
        }
        decreaseOutstandingBondDebt(toClaim);
        return toClaim;
    }

    //=================================================================================================================
    //  Internal Functions
    //=================================================================================================================

    function claimFromBond(address inBonder, uint256 nonce) internal returns (uint256) {
        uint256 remainingToClaim = PhantomStorage().getUint(
            keccak256(abi.encodePacked(phantom.bonding.remaining_payout_for, inBonder, nonce))
        );
        uint256 timeofLastClaim = PhantomStorage().getUint(
            keccak256(abi.encodePacked(phantom.bonding.last_claim_at, inBonder, nonce))
        );
        uint256 timeOfFullVest = PhantomStorage().getUint(
            keccak256(abi.encodePacked(phantom.bonding.vests_at_timestamp, inBonder, nonce))
        );
        uint256 toClaim = 0;

        if (block.timestamp >= timeOfFullVest) {
            // Only allow claim at the end
            toClaim = remainingToClaim;
            remainingToClaim -= toClaim;
            if (remainingToClaim == 0 && nonce == lowestNonceStillVesting(inBonder)) {
                incrementLowestNonceStillVesting(inBonder);
            }
            PhantomStorage().setUint(
                keccak256(abi.encodePacked(phantom.bonding.remaining_payout_for, inBonder, nonce)),
                remainingToClaim
            );
            PhantomStorage().setUint(
                keccak256(abi.encodePacked(phantom.bonding.last_claim_at, inBonder, nonce)),
                block.timestamp
            );
        }

        return toClaim;
    }

    function calculateAndSetVestingTimeForBond(
        bytes calldata inBondType,
        address inBonder,
        uint256 nonce
    ) internal {
        uint256 vest_length = PhantomStorage().getUint(
            keccak256(abi.encodePacked(phantom.bonding.vest_length, inBondType))
        );
        PhantomStorage().setUint(
            keccak256(abi.encodePacked(phantom.bonding.vests_at_timestamp, inBonder, nonce)),
            block.timestamp + vest_length
        );
        PhantomStorage().setUint(
            keccak256(abi.encodePacked(phantom.bonding.last_claim_at, inBonder, nonce)),
            block.timestamp
        );
    }

    function setTokenForBond(
        address inBonder,
        uint256 nonce,
        address token
    ) internal {
        PhantomStorage().setAddress(
            keccak256(abi.encodePacked(phantom.bonding.token, inBonder, nonce)),
            token
        );
    }

    function setPayoutForBond(
        address inBonder,
        uint256 nonce,
        uint256 payout
    ) internal {
        PhantomStorage().setUint(
            keccak256(abi.encodePacked(phantom.bonding.remaining_payout_for, inBonder, nonce)),
            payout
        );
    }

    //=================================================================================================================
    //  Nonce Managment
    //=================================================================================================================

    function incrementLowestNonceAssignable(address inBonder) internal {
        PhantomStorage().addUint(
            keccak256(abi.encodePacked(phantom.bonding.user.lowest_assignable_nonce, inBonder)),
            1
        );
    }

    function lowestNonceAssignable(address inBonder) public view returns (uint256) {
        return
            PhantomStorage().getUint(
                keccak256(abi.encodePacked(phantom.bonding.user.lowest_assignable_nonce, inBonder))
            );
    }

    function incrementLowestNonceStillVesting(address inBonder) internal {
        PhantomStorage().addUint(
            keccak256(abi.encodePacked(phantom.bonding.user.lowest_nonce_still_vesting, inBonder)),
            1
        );
    }

    function lowestNonceStillVesting(address inBonder) public view returns (uint256) {
        return
            PhantomStorage().getUint(
                keccak256(abi.encodePacked(phantom.bonding.user.lowest_nonce_still_vesting, inBonder))
            );
    }

    function bondingMultiplierFor(address inToken, bytes calldata inBondType) internal view returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.bonding.multiplier, inToken, inBondType)));
    }

    function bondProfitRatio() internal view returns (uint256) {
        return PhantomStorage().getUint(keccak256(phantom.bonding.profit_ratio));
    }

    function increaseOutstandingBondDebt(uint256 amount) internal {
        PhantomStorage().addUint(keccak256(phantom.bonding.debt), amount);
    }

    function decreaseOutstandingBondDebt(uint256 amount) internal {
        PhantomStorage().subUint(keccak256(phantom.bonding.debt), amount);
    }

    function outstandingBondDebt() internal view returns (uint256) {
        return PhantomStorage().getUint(keccak256(phantom.bonding.debt));
    }

    function safeToBond(address user, uint256 rewardForDeposit) public view returns (bool) {
        if (PHM().balanceAllDenoms(user) + rewardForDeposit > PHM().maxBalancePerWallet()) return false;
        uint256 maxDebtRatio = PhantomStorage().getUint(keccak256(phantom.bonding.max_debt_ratio)); // fixed point
        return (outstandingBondDebt() + rewardForDeposit).div(PHM().totalSupply()) > maxDebtRatio ? false : true;
    }

    function isValidBond(address inToken) internal view returns (bool) {
        return PhantomStorage().getBool(keccak256(abi.encodePacked(phantom.bonding.is_valid, inToken)));
    }
}
