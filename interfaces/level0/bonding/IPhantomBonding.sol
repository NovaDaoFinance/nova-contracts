/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */


/**
 * @title IPhantomBonding
 * @author PhantomDao Team
 * @notice The Interface for IPhantomBonding
 */
interface IPhantomBonding {
    event PhantomBonding_BondCreated(address forUser, uint256 payout, uint256 nonce);
    event PhantomBonding_BondRedeemed(address forUser, uint256 payout, uint256 nonce);
    error PhantomBondingError_IsNotValidBondingToken(address inToken);
    error PhantomBondingError_ExceedsDebtLimit();
    function createBond(address inBonder, uint256 inAmount, address inToken, bytes calldata inBondType) external returns(uint256);
    function redeemBonds(address inBonder, bool autoStake) external returns(uint256);
}