/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

interface IPhantomTWAP {
    function update() external;
    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint amountOut);
}