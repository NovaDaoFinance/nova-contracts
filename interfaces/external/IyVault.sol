/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IYearnRouter
 * @author PhantomDao Team
 * @notice The Inteface for IyVault
 */
interface IyVault {
    function token() external returns (IERC20);
    function deposit(uint256 amount, address recipient) external;
    function withdraw(uint256 maxShares, address receipient, uint256 maxLoss) external;
}