/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomFounders
 * @author PhantomDao Team
 * @notice The Inteface for PhantomFounders
 */
interface IPhantomFounders {

    /**
     * @dev set the start date for vesting
     */
    function startVesting() external;

    /**
     * @dev add a foudner's wallet to the whitelist with an amount of tokens
     */
    function registerFounder(address founder, uint256 amount) external;

    /**
     * @dev claim fPHM
     */
    function claim(address founder) external;

    /**
     * @dev swap vested fPHM for gPHM
     */
    function exercise(address founder) external;

}