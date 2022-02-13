/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title ISpiritSwapGauge
 * @author PhantomDao Team
 * @notice The Inteface for ISpiritSwapGauge
 */
interface ISpiritSwapGauge {
    
    function TOKEN() external returns (IERC20);
    function deposit(uint256 amount) external;
    function withdrawAll() external;
}