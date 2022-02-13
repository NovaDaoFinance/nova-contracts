/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* External Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @title IgPHM
 * @author PhantomDao Team
 * @notice The Interface for IPhantomERC20
 */
interface IPhantomERC20 is IERC20, IERC20Permit {
    /**
     * @dev mint new tokens
     * @param toUser the owner of the new tokens
     * @param inAmount number of new tokens to be minted
     */
    function mint(address toUser, uint256 inAmount) external;

    /**
     * @dev burn a user's tokens
     * @param fromUser the user whos tokens are to be burned
     * @param inAmount the number of tokens to burn
     */
    function burn(address fromUser, uint256 inAmount) external;
} 