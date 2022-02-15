/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* Package Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomERC20} from "../../interfaces/core/erc20/IPhantomERC20.sol";
import {IPhantomTreasury} from "../../interfaces/core/IPhantomTreasury.sol";
import {IyVault} from "../../interfaces/external/IyVault.sol";
import {IPhantomTWAP} from "../../interfaces/core/IPhantomTWAP.sol";

/**
 * @title PhantomTreasury
 * @author PhantomDao Team
 * @notice The contract responsible for handle all token transactions
 */
contract PhantomTreasury is PhantomStorageMixin, IPhantomTreasury {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IPhantomERC20;

    address[] reserveTokens;
    mapping(address => bool) _isReserveToken;
    address constant FRAX = 0xaf319E5789945197e365E7f7fbFc56B130523B33;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    function swap(
        address forUser,
        uint256 inAmount,
        address inToken,
        uint256 outAmount,
        address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external virtual override onlyRegisteredContracts {
        transferFromUserToVault(forUser, inAmount, inToken, keys, percentages);
        transferFromVaultToUser(forUser, outAmount, outToken, keys, percentages);
        emit PhantomTreasury_Swap(inToken, outToken, forUser, inAmount);
    }

    function swapBurn(
        address forUser,
        uint256 burnAmount,
        address burnToken,
        uint256 outAmount,
        address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external virtual override onlyRegisteredContracts requirePHMTypeToken(burnToken) {
        // Burn
        IPhantomERC20(burnToken).safeTransferFrom(forUser, address(PhantomVault()), burnAmount);
        PhantomVault().burn(burnAmount, burnToken);
        // Swap
        transferFromVaultToUser(forUser, outAmount, outToken, keys, percentages);
        emit PhantomTreasury_SwapBurn(burnToken, outToken, forUser, burnAmount);
    }

    function swapMint(
        address forUser,
        uint256 inAmount,
        address inToken,
        uint256 mintAmount,
        address mintToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external virtual override onlyRegisteredContracts requirePHMTypeToken(mintToken) {
        transferFromUserToVault(forUser, inAmount, inToken, keys, percentages);
        IPhantomERC20(mintToken).mint(forUser, mintAmount);
        emit PhantomTreasury_SwapMint(inToken, mintToken, forUser, inAmount);
    }

    function swapBurnMint(
        address forUser,
        uint256 burnAmount,
        address burnToken,
        uint256 mintAmount,
        address mintToken
    ) external virtual override onlyRegisteredContracts requirePHMTypeToken(mintToken) {
        // Burn
        IERC20(burnToken).safeTransferFrom(forUser, address(PhantomVault()), burnAmount);
        PhantomVault().burn(burnAmount, burnToken);
        // Mint
        IPhantomERC20(mintToken).mint(forUser, mintAmount);
        emit PhantomTreasury_SwapBurnMint(burnToken, burnAmount, forUser, mintAmount, mintToken);
    }

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
    ) external virtual override onlyRegisteredContracts returns (uint256) {
        require(_isReserveToken[inToken], "PhantomTreasury: inToken isn't a reserve token");

        // For a given bonding token retrieve the desired oracle to use for bond pricing
        IPhantomTWAP twap = PhantomBondPricing(inToken);
        require(address(twap) != address(0), "PhantomTreasury: No TWAP deployed for inToken");
        // Trigger an update to get the latest price
        twap.update();

        // Get Quote
        uint256 quote = twap.consult(inToken, inAmount);
        // if (quote > excessReserves()) revert PhantomTreasury_InsufficientReserves(inAmount);
        transferFromUserToVault(inDepositor, inAmount, inToken, keys, percentages);
        // Apply the bond discount and mint the reward for the deposit
        uint256 mintAmount = quote.mul(mintRatio);
        splitCredit(mintAmount, address(PHM()), keys, percentages);
        PHM().mint(address(PhantomVault()), mintAmount);
        // Mint profits
        uint256 profitAmount = mintAmount.mul(profitRatio);
        PHM().mint(address(PhantomVault()), profitAmount);
        splitCredit(profitAmount, address(PHM()), profitKeys, profitPercentages);
        emit PhantomTreasury_Minted(address(PHM()), address(PhantomVault()), mintAmount + profitAmount);
        return mintAmount;
    }

    function withdraw(
        address outWithdrawer,
        uint256 outAmount,
        address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages,
        uint256 burnRatio
    ) external virtual override onlyRegisteredContracts returns (uint256) {
        require(_isReserveToken[outToken], "PhantomTreasury: outToken isn't a reserve token");

        // For a given bonding token retrieve the desired oracle to use for bond pricing

        IPhantomTWAP twap = PhantomBondPricing(outToken);
        require(address(twap) != address(0), "PhantomTreasury: No TWAP deployed for outToken");
        // Trigger an update to get the latest price
        twap.update();

        // Get Quote
        uint256 quote = twap.consult(outToken, outAmount);
        uint256 burnAmount = quote.mul(burnRatio);
        PhantomVault().burn(burnAmount, address(PHM()));
        splitDebit(burnAmount, address(PHM()), keys, percentages);
        transferFromVaultToUser(outWithdrawer, outAmount, outToken, keys, percentages);
        return burnAmount;
    }

    function sendToYearn(
        address vault,
        uint256 amount,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external override onlyRegisteredContracts {
        IERC20 token = IyVault(vault).token();
        transferFromVaultToUser(address(this), amount, address(token), keys, percentages);
        token.approve(vault, amount);
        IyVault(vault).deposit(amount, address(this));
        transferFromUserToVault(address(this), amount, vault, keys, percentages);
    }

    function withdrawFromYearn(
        address vault,
        uint256 maxShares,
        uint256 maxLoss,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external override onlyRegisteredContracts {
        IERC20 token = IyVault(vault).token();
        transferFromVaultToUser(address(this), maxShares, vault, keys, percentages);
        IERC20(vault).approve(vault, maxShares);
        IyVault(vault).withdraw(maxShares, address(this), maxLoss);
        transferFromUserToVault(address(this), token.balanceOf(address(this)), address(token), keys, percentages);
    }

    /**
     * @dev register a token as being one of the reserve tokens
     */
    function registerReserveToken(address token) external override onlyRegisteredContracts {
        require(_isReserveToken[token] == false, "Token already registered");
        reserveTokens.push(token);
        _isReserveToken[token] = true;
    }

    function sumReserves() public view override returns (uint256) {
        uint256 S;
        for (uint256 i; i < reserveTokens.length; i++) {
            IPhantomTWAP twap = PhantomBondPricing(reserveTokens[i]);
            require(address(twap) != address(0), "PhantomTreasury: No twap registered for reserve token");

            S += twap.consult(
                reserveTokens[i], 
                IERC20(reserveTokens[i]).balanceOf(address(PhantomVault())).mul(standardAccountPercentages()[0])
            );
        }
        return S;
    }

    //=================================================================================================================
    // Public Functions
    //=================================================================================================================

    function isReserveToken(address token) public view returns (bool) {
        return _isReserveToken[token];
    }

    //=================================================================================================================
    // Internal Functions
    //=================================================================================================================

    function transferFromUserToVault(
        address forUser,
        uint256 inAmount,
        address inToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) internal {
        if (inAmount == 0 || inToken == address(0)) return;
        splitCredit(inAmount, inToken, keys, percentages);
        IERC20(inToken).safeTransferFrom(forUser, address(PhantomVault()), inAmount);
    }

    function transferFromVaultToUser(
        address forUser,
        uint256 outAmount,
        address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) internal {
        /*
         * Vault only ever sends to the Treasury, this intermediate step increases gas consumption
         * but provides an extra layer of security. By doing this step in two transfers the Vault never has to be approved
         * to withdrawl directly to a users wallet. Overkill? Probably, but risk mitigation is important.
         * TODO: Discuss this design choice
         */
        if (outAmount == 0 || outToken == address(0)) return;
        splitDebit(outAmount, outToken, keys, percentages);
        PhantomVault().withdraw(outAmount, outToken);
        IERC20(outToken).safeTransfer(forUser, outAmount);
    }

    function excessReserves() internal returns (uint256) {
        uint256 supply = PHM().totalSupply();
        uint256 balance;
        for (uint256 i; i < reserveTokens.length; i++) {
            IPhantomTWAP twap = PhantomBondPricing(reserveTokens[i]);
            require(address(twap) != address(0), "PhantomTreasury: No twap registered for reserve token");

            twap.update();
            balance += twap.consult(
                reserveTokens[i], 
                getBalanceFor(reserveKey()[0], reserveTokens[i])
            );
        }

        if (balance < supply) return 0;
        return balance - supply;
    }

    function getBalanceFor(bytes32 accountKey, address token) internal view returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.treasury.balances, token, accountKey)));
    }

    function increaseBalanceFor(
        bytes32 accountKey,
        address token,
        uint256 amount
    ) internal {
        PhantomStorage().addUint(keccak256(abi.encodePacked(phantom.treasury.balances, token, accountKey)), amount);
    }

    function decreaseBalanceFor(
        bytes32 accountKey,
        address token,
        uint256 amount
    ) internal {
        if (
            PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.treasury.balances, token, accountKey))) < amount
        ) {
            revert PhantomTreasury_InsufficientBalance(amount, token);
        }
        PhantomStorage().subUint(keccak256(abi.encodePacked(phantom.treasury.balances, token, accountKey)), amount);
    }

    function isPHMTypeToken(address inToken) internal view returns (bool) {
        return
            inToken == address(PHM()) ||
            inToken == address(sPHM()) ||
            inToken == address(fPHM()) ||
            inToken == address(aPHM()) ||
            inToken == address(gPHM());
    }

    function splitDebit(
        uint256 outAmount,
        address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) internal {
        if (sum(percentages) != 1e18) revert PhantomTreasury_PercentagesDoNotAddTo100();
        if (keys.length != percentages.length) revert PhantomTreasury_LengthsDoNotMatch();
        for (uint256 i = 0; i < keys.length; i += 1) {
            decreaseBalanceFor(keys[i], outToken, outAmount.mul(percentages[i]));
        }
    }

    function splitCredit(
        uint256 inAmount,
        address inToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) internal {
        if (sum(percentages) != 1e18) revert PhantomTreasury_PercentagesDoNotAddTo100();
        if (keys.length != percentages.length) revert PhantomTreasury_LengthsDoNotMatch();
        for (uint256 i = 0; i < keys.length; i += 1) {
            increaseBalanceFor(keys[i], inToken, inAmount.mul(percentages[i]));
        }
    }

    function sum(uint256[] memory data) public pure returns (uint256) {
        uint256 S;
        for (uint256 i; i < data.length; i++) {
            S += (data[i]);
        }
        return S;
    }

    //=================================================================================================================
    // Modifiers
    //=================================================================================================================

    modifier requirePHMTypeToken(address inToken) {
        if (!isPHMTypeToken(inToken)) revert PhantomTreasury_InvalidToken(inToken);
        _;
    }
}
