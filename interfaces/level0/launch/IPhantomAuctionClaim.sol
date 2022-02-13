/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomAuctionClaim
 * @author PhantomDao Team
 * @notice The Inteface for PhantomAuctionClaim
 */
interface IPhantomAuctionClaim {

    function registerAllotment(address claimer, uint256 amount) external;
    function purchase(address claimer) external;
    function remainingAllotment(address claimer) external returns (uint256);

}