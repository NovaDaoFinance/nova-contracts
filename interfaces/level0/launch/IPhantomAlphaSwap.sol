/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomAlphaSwap
 * @author PhantomDao Team
 * @notice The Interface for PhantomAlphaSwap
 */
interface IPhantomAlphaSwap {

    function swap(address claimer) external;

}