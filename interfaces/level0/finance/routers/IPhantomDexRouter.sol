/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomSpiritRouter
 * @author PhantomDao Team
 * @notice Interface of PhantomSpiritRouter
 */
interface IPhantomDexRouter {

    function getQuote(
        address dexRouter,
        address dexFactory,
        uint256 inAmount,
        address inToken,
        address outToken
    ) external view returns (uint256);

    function swapReceiveMinimum(
        address dexRouter,
        uint256 inAmount,
        uint256 minOutAmount,
        address[] memory path,
        uint256 deadline,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;

    function swapSpendMaximum(
        address dexRouter,
        uint256 outAmount,
        uint256 maxInAmount,
        address[] memory path,
        uint256 deadline,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;
}
