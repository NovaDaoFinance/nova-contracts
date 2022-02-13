/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Interface Import */
import {IPhantomERC20} from "./IPhantomERC20.sol";

/**
 * @title IPHM
 * @author PhantomDao Team
 * @notice The Interface for IPHM
 */
interface IPHM is IPhantomERC20 {
    function addUncappedHolder(address addr) external;
    function removeUncappedHolder(address addr) external;
    function balanceAllDenoms(address user) external view returns(uint256);
    function maxBalancePerWallet() external view returns (uint256);

} 