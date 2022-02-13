/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomLaunch
 * @author PhantomDao Team
 * @notice The Inteface for PhantomLauch
 */
interface IPhantomLaunch {

    /**
     * @dev claim aPHM tokens
     */
    function claimAPHM() external;

    /**
     * @dev swap aPHM for PHM on a 1:1 basis.
     */
    function swapAPHM() external;

    /**
     * @dev claim fPHM tokens
     */
    function claimFPHM() external;

    /**
     * @dev swap vested fPHM for gPHM
     */ 
    function exerciseFPHM() external; 

}