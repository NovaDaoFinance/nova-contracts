/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomExecutor
 * @author PhantomDao Team
 * @notice The Interface for IPhantomExecutor
 */
interface IPhantomExecutor {
    event ProposalQueued(uint256 proposalId, uint256 eta);
}