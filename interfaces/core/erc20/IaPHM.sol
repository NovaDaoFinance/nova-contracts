/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Interface Import */
import {IPhantomERC20} from "./IPhantomERC20.sol";

/**
 * @title IPHM
 * @author PhantomDao Team
 * @notice The Interface for IPHM
 */
interface IaPHM is IPhantomERC20 {

    function addApprovedAddress(address addr) external;
    function addApprovedAddresses(address[] calldata addrs) external;
    function removeApprovedAddress(address addr) external;
    function removeApprovedAddresses(address[] calldata addrs) external;

} 