/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */


/**
 * @title IPhantomTreasury
 * @author PhantomDao Team
 * @notice The Interface for IPhantomTreasury
 */
interface IPhantomTreasury {

    //=================================================================================================================
    // Errors
    //=================================================================================================================

    error PhantomTreasury_InvalidToken(address inToken);
    error PhantomTreasury_InsufficientBalance(uint256 numMint, address token);
    error PhantomTreasury_InsufficientReserves(uint256 numMint);
    error PhantomTreasury_UnapprovedExternalCall(address target, uint256 value, bytes data);
    error PhantomTreasury_ExternalCallReverted(address target, uint256 value, bytes data);
    error PhantomTreasury_ExternalReturnedInsufficientTokens(uint256 num, address target, uint256 value, bytes data);
    error PhantomTreasury_ExternalReturnedNoTokens(address target, uint256 value, bytes data);
    error PhantomTreasury_PercentagesDoNotAddTo100();
    error PhantomTreasury_LengthsDoNotMatch();
    
    //=================================================================================================================
    // Events
    //=================================================================================================================
    
    event PhantomTreasury_Swap(address inToken, address outToken, address forUser, uint256 amount);
    event PhantomTreasury_SwapBurn(address inToken, address outToken, address forUser, uint256 amount);
    event PhantomTreasury_SwapMint(address inToken, address outToken, address forUser, uint256 amount);
    event PhantomTreasury_SwapBurnMint(address burnToken, uint256 burnAmount, address forUser, uint256 mintAmount, address mintToken);
    event PhantomTreasury_Minted(address inToken, address toUser, uint256 amount);
    event PhantomTreasury_Burned(address inToken, address fromUser, uint256 amount);
    event PhantomTreasury_DepositedToVault(address inToken, address fromUser, uint256 amount);
    event PhantomTreasury_WithdrawalFromVault(address inToken, address toUser, uint256 amount);
    
    //=================================================================================================================
    // Public Functions
    //=================================================================================================================
    /**
     * @dev deposit funds into the treasury
     * @param inDepositor who is depositing the money?
     * @param inAmount how much is being deposited?
     * @param inToken what type of token is being deposited?
     * @param keys which accounts to credit
     * @param percentages what percentages to credit each account. Should match layout of keys.
     * @param keys which balances need to be updated
     * @param percentages what percentage of this transaction should be attributed to each balance
     * @param mintRatio what discount to apply to price of inToken in order to determine how many PHM to mint.
     * @param profitRatio want multiplier to use to determine DAO profit amount in PHM
     * @param profitKeys where DAO profit should be credited to
     * @param profitPercentages in what percentages should the profit be allocated across profitKeys 
     * @return the amount deposited
     */
    function deposit(
        address inDepositor, 
        uint256 inAmount, 
        address inToken, 
        bytes32[] memory keys,
        uint256[] memory percentages, 
        uint256 mintRatio,
        uint256 profitRatio,
        bytes32[] memory profitKeys,
        uint256[] memory profitPercentages
    ) external returns (uint256);

    /**
     * @dev Withdraw funds from the treasury
     * @param outWithdrawer who is withdrawing the funds?
     * @param outAmount how much is being withdrawn?
     * @param outToken what type of token is being withdrawn?
     * @param keys which balances need to be updated
     * @param percentages what percentage of this transaction should be attributed to each balance
     * @param burnRatio what discount to apply to price of inToken in order to determine how many PHM to burn.
     * @return the amount withdrawn
     */
    function withdraw(
        address outWithdrawer, 
        uint256 outAmount, 
        address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages, 
        uint256 burnRatio
    ) external returns (uint256);

    /**
     * @dev swap some tokens in the treasury for another type of token
     * @param forUser who is doing this swap?
     * @param inAmount amount of tokens to be swapped
     * @param inToken the token type being swapped
     * @param outAmount the amount of new tokens to receive in exchange
     * @param outToken the type of token to receive in exchange
     * @param keys which balances need to be updated
     * @param percentages what percentage of this transaction should be attributed to each balance
     */
    function swap(
        address forUser,
        uint256 inAmount,
        address inToken,
        uint256 outAmount,
        address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;

    /**
     * @dev swap some tokens in the treasury for another type of token, burning the original tokens
     * @param forUser who is doing this swap?
     * @param burnAmount amount of tokens to be brned
     * @param burnToken the token type being burned
     * @param outAmount the amount of new tokens to receive in exchange
     * @param outToken the type of token to receive in exchange
     * @param keys which balances need to be updated
     * @param percentages what percentage of this transaction should be attributed to each balance
     */
    function swapBurn(
        address forUser,
        uint256 burnAmount,
        address burnToken,
        uint256 outAmount,
        address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;

    /**
     * @dev swap some tokens in the treasury for another type of newly minted tokens
     * @param forUser who is doing this swap?
     * @param inAmount amount of tokens to be swapped
     * @param inToken the token type being swapped
     * @param mintAmount the amount of new tokens to be minted and receive in exchange
     * @param mintToken the type of token to be minted and receive in exchange
     * @param keys which balances need to be updated
     * @param percentages what percentage of this transaction should be attributed to each balance
     */
    function swapMint(
        address forUser,
        uint256 inAmount,
        address inToken,
        uint256 mintAmount,
        address mintToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;


    /**
     * @dev burn an amount of tokens and mint an amount of tokens in its place
     * @param forUser who is doing this swap?
     * @param burnAmount amount of tokens to be burned
     * @param burnToken the token type being burned
     * @param mintAmount the amount of new tokens to be minted and receive in exchange
     * @param mintToken the type of token to be minted and receive in exchange
     */
    function swapBurnMint(
        address forUser,
        uint256 burnAmount,
        address burnToken,
        uint256 mintAmount,
        address mintToken
    ) external;

    function sendToYearn(address vault, uint256 amount, bytes32[] memory keys, uint256[] memory percentages) external;
    function withdrawFromYearn(address vault, uint256 maxShares, uint256 maxLoss, bytes32[] memory keys, uint256[] memory percentages) external;
    function registerReserveToken(address token) external;
    function sumReserves() external view returns (uint256);
    function isReserveToken(address token) external view returns (bool);
}
