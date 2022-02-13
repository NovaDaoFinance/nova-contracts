/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomFinance
 * @author PhantomDao Team
 * @notice The Inteface for PhantomFinance
 */
interface IPhantomFinance {
    function stake(uint256 inAmount) external;
    function unstake(uint256 inAmount) external;
    function wrap(uint256 inAmount) external;
    function unwrap(uint256 inAmount) external;
    function bond(
        uint256 inAmount,
        address inToken,
        bytes calldata inBondType
    ) external;
    function donate(uint256 inAmount,address inToken) external;
}