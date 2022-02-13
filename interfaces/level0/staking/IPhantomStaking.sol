/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomStaking
 * @author PhantomDao Team
 * @notice The Interface for PhantomGovernor
 */
interface IPhantomStaking {
    function stake(address inStaker, uint256 inAmount) external;
    function unstake(address inUnstaker, uint256 inAmount) external;
    function wrap(address toUser, uint256 amount) external returns(uint256);
    function unwrap(address toUser, uint256 amount) external returns(uint256);
    function attemptRebase() external;
}