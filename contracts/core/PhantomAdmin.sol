/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {DSAuth} from "../libs/DSAuth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../mixins/PhantomStorageMixin.sol";

/**
 * @title PhantomAdmin
 */
contract PhantomAdmin is PhantomStorageMixin, DSAuth {
    using PRBMathUD60x18 for uint256;

    constructor(address storageAddress) PhantomStorageMixin(storageAddress) DSAuth() {
        return;
    }

    //=================================================================================================================
    // Staking
    //=================================================================================================================

    function updateStakingRewardRate(uint256 newRewardRate) external auth {
        require(newRewardRate <= 1e18, "rewardRate must be less than or euqal to 1e18 aka 100%");
        sPHM().updateRewardRate(newRewardRate);
    }

    //=================================================================================================================
    // Bonding
    //=================================================================================================================

    /**
     * @notice % Add/Remove tokens from being bondable
     */
    function addTokenToBondingList(address inToken) public auth {
        PhantomStorage().setBool(keccak256(abi.encodePacked(phantom.bonding.is_valid, inToken)), true);
    }

    function addMultipleTokensToBondingList(address[] calldata inTokens) external auth {
        for (uint256 i = 0; i < inTokens.length; i += 1) {
            addTokenToBondingList(inTokens[i]);
        }
    }

    function removeTokenFromBondingList(address inToken) public auth {
        PhantomStorage().deleteBool(keccak256(abi.encodePacked(phantom.bonding.is_valid, inToken)));
    }

    function removeMultipleTokensToBondingList(address[] calldata inTokens) external auth {
        for (uint256 i = 0; i < inTokens.length; i += 1) {
            removeTokenFromBondingList(inTokens[i]);
        }
    }

    function isValidTokenForBond(address inToken) external view returns (bool) {
        return PhantomStorage().getBool(keccak256(abi.encodePacked(phantom.bonding.is_valid, inToken)));
    }

    /**
     * Set the debt limit for bonding.
     * @param limit the debt limit expressed as a ratio of PHM total suppyl
     */
    function setBondLimit(uint256 limit) external auth {
        PhantomStorage().setUint(keccak256("phantom.bonding.max_debt_ratio"), limit);
    }

    function currentBondRatio() external view returns (uint256) {
        return PhantomStorage().getUint(keccak256(phantom.bonding.debt)).div(PHM().totalSupply());
    }

    /**
     * @notice Add a new bondtype with vesting length in seconds
     */
    function addBondType(bytes calldata bondType, uint256 vestInSeconds) external auth {
        PhantomStorage().setBool(keccak256(abi.encodePacked(phantom.bonding.is_valid, bondType)), true);
        PhantomStorage().setUint(
            keccak256(abi.encodePacked("phantom.bonding.type.vest_length", bondType)),
            vestInSeconds
        );
    }

    /**
     * @notice Remove a bond type
     */
    function removeBondType(bytes calldata bondType) external auth {
        PhantomStorage().deleteBool(keccak256(abi.encodePacked(phantom.bonding.is_valid, bondType)));
        PhantomStorage().deleteUint(keccak256(abi.encodePacked(phantom.bonding.vest_length, bondType)));
    }

    /**
     * @notice Get info about a bond type
     */
    function infoOfBondType(bytes calldata bondType) external view returns (bool, uint256) {
        bool isValid = PhantomStorage().getBool(keccak256(abi.encodePacked(phantom.bonding.is_valid, bondType)));
        uint256 vestInBlocks = PhantomStorage().getUint(
            keccak256(abi.encodePacked(phantom.bonding.vest_length, bondType))
        );
        return (isValid, vestInBlocks);
    }

    // 18 decimals 1e18 = 1x, 2e18 = 2x/100%, 3e18 = 3x/200%
    function setBondingMultiplierFor(
        bytes calldata inBondType,
        address inToken,
        uint256 value
    ) external auth {
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.bonding.multiplier, inBondType, inToken)), value);
    }

    function bondingMultiplierFor(bytes calldata inBondType, address inToken) external view returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.bonding.multiplier, inBondType, inToken)));
    }

    function registerTWAPAggregator(address twap, address forToken) external auth {
        PhantomStorage().registerContract(
            abi.encodePacked(phantom.contracts.bondpricing, forToken), 
            twap
        );
    }

    function registerTWAP(address twap, address forPair) external auth {
        PhantomStorage().registerContract(
            abi.encodePacked(phantom.contracts.twap, forPair), 
            twap
        );
    }

    function maxBondPayoutPHM() external view returns (uint256) {
        uint256 maxDebtRatio = PhantomStorage().getUint(keccak256(phantom.bonding.max_debt_ratio)); // fixed point
        uint256 outstandingBondDebt = PhantomStorage().getUint(keccak256(phantom.bonding.debt));
        uint256 maxDebt = PHM().totalSupply().mul(maxDebtRatio);

        if (maxDebt >= outstandingBondDebt) return 0;
        return maxDebt - outstandingBondDebt;
    }

    //=================================================================================================================
    // Protocol Management
    //=================================================================================================================

    function setSpiritAsDefaultDex() external auth {
        PhantomStorage().setAddress(
            keccak256(phantom.routing.dex_router_address),
            PhantomStorage().getAddress(keccak256(phantom.routing.spirit_router_address))
        );
        PhantomStorage().setAddress(
            keccak256(phantom.routing.dex_factory_address),
            PhantomStorage().getAddress(keccak256(phantom.routing.spirit_factory_address))
        );
    }

    function setSpookyAsDefaultDex() external auth {
        PhantomStorage().setAddress(
            keccak256(phantom.routing.dex_router_address),
            PhantomStorage().getAddress(keccak256(phantom.routing.spooky_router_address))
        );
        PhantomStorage().setAddress(
            keccak256(phantom.routing.dex_factory_address),
            PhantomStorage().getAddress(keccak256(phantom.routing.spooky_factory_address))
        );
    }

    function setCustomDefaultDex(address dexRouter, address dexFactory) external auth {
        PhantomStorage().setAddress(keccak256(phantom.routing.dex_router_address), dexRouter);
        PhantomStorage().setAddress(keccak256(phantom.routing.dex_factory_address), dexFactory);
    }

    /**
     * Exchange reserves, going via path to do the exchange. The first and last element of the
     * path must be reserve tokens. Transaction will revert if the minInAmount of tokens isn't
     * received for the exchange.
     */
    function rebalanceReserveTokens(
        address[] memory path, 
        uint256 outAmount, 
        uint256 minInAmount, 
        uint256 deadline
    ) external auth {
        address outToken = path[0];
        address inToken = path[path.length-1];
        require(
            PhantomTreasury().isReserveToken(outToken), 
            "PhantomAdmin: first token in path isn't a reserve token"
        );
        require(
            PhantomTreasury().isReserveToken(inToken), 
            "PhantomAdmin: last token in path isn't a reserve token"
        );
        require(
            IERC20(outToken).balanceOf(address(PhantomVault())) >= outAmount, 
            "PhantomAdmin: Vault balance of outToken is too low"
        );
        PhantomDexRouter().swapSpendMaximum(
            PhantomStorage().getAddress(keccak256(phantom.routing.dex_router_address)),
            outAmount,
            minInAmount,
            path,
            deadline,
            standardAccountKeys(),
            standardAccountPercentages()
        );
    }

    //=================================================================================================================
    // Employee Management
    //=================================================================================================================

    // function hireEmployee(address employee, uint256 salary) external auth {
    //     PhantomPayments().addEmployee(employee, salary, address(PHM()));
    // }

    // function fireEmployee(address employee, uint256 salary) external auth {
    //     PhantomPayments().deleteEmployee(employee);
    // }

    // function changeSalary(address employee, uint256 newSalary) external auth {
    //     PhantomPayments().modifyEmployee(employee, address(PHM()), newSalary);
    // }

    //=================================================================================================================
    // DAO Operations Funds
    //=================================================================================================================

    function withdrawOpsDAOFunds(address destination, uint256 amount) external auth {
        PhantomTreasury().swap(
            destination,
            (0), 
            address(0), 
            amount, 
            address(PHM()), 
            daoKey(), 
            percentage100()
        );
    }

    function opsDAOBalance() external view returns (uint256) {
        return PhantomStorage().getUint(keccak256(
            abi.encodePacked(phantom.treasury.balances, address(PHM()), daoKey()))
        );
    }

    //=================================================================================================================
    // Protocol Information
    //=================================================================================================================

    function treasuryTokenBalance(address token) external view returns (uint256) {
        bytes32[] memory keys = standardAccountKeys();
        uint256 balance;
        for (uint256 i; i < keys.length; i++) {
            balance += PhantomStorage().getUint(
                keccak256(abi.encodePacked(phantom.treasury.balances, token, keys[i]))
            );
        }
        return balance;
    }

    function reservesTokenBalance(address token) external view returns (uint256) {
        bytes32[] memory keys = reserveKey();
        uint256 balance;
        for (uint256 i; i < keys.length; i++) {
            balance += PhantomStorage().getUint(
                keccak256(abi.encodePacked(phantom.treasury.balances, token, keys[i]))
            );
        }
        return balance;
    }
}
