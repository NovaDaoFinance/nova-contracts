/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomVault
 * @author PhantomDao Team
 * @notice The Interface for IPhantomVault
 */
interface IPhantomVault {

    //=================================================================================================================
    // Events
    //=================================================================================================================

    event PhantomVault_Withdrawal(address fromUser, uint256 outAmount, address outToken);
    event PhantomVault_Burned(address fromUser, uint256 outAmount, address outToken);

    //=================================================================================================================
    // Functions
    //=================================================================================================================

    /**
     * @dev Withdraw ERC20 tokens from the Vault
     * @param outAmount The number of tokens to be withdrawn
     * @param outToken The type of token to withdraw
     */
    function withdraw(uint256 outAmount, address outToken) external;

    /**
     * @dev Burn ERC20 tokens from the Vault
     * @param burnAmount the number of tokens to be burned
     * @param burnToken The address of the ERC20 token to burn
     */
    function burn(uint256 burnAmount, address burnToken) external;
}