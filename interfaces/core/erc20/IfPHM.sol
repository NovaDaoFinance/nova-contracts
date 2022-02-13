/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Interface Import */
import {IPhantomERC20} from "./IPhantomERC20.sol";

/**
 * @title IPHM
 * @author PhantomDao Team
 * @notice The Interface for IPHM
 */
interface IfPHM is IPhantomERC20 {

    /**
     * @dev burn a user's tokens
     * @param fromUser the user whos tokens are to be burned
     * @param inAmount the number of tokens to burn
     */
    function burn(address fromUser, uint256 inAmount) external;

    function addApprovedAddress(address seller) external;
    function addApprovedAddresses(address[] calldata sellers) external;
    function removeApprovedAddress(address seller) external;
    function removeApprovedAddresses(address[] calldata sellers) external;

} 