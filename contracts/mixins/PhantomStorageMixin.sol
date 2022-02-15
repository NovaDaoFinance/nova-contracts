/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/* Internal Imports */
import {PhantomStorageKeys} from "../storage/PhantomStorageKeys.sol";

/* Internal Interface Imports */
import {IPHM} from "../../interfaces/core/erc20/IPHM.sol";
import {IsPHM} from "../../interfaces/core/erc20/IsPHM.sol";
import {IgPHM} from "../../interfaces/core/erc20/IgPHM.sol";
import {IfPHM} from "../../interfaces/core/erc20/IfPHM.sol";
import {IaPHM} from "../../interfaces/core/erc20/IaPHM.sol";
import {IPhantomAlphaSwap} from "../../interfaces/level0/launch/IPhantomAlphaSwap.sol";
import {IPhantomBonding} from "../../interfaces/level0/bonding/IPhantomBonding.sol";
import {IPhantomFounders} from "../../interfaces/level0/launch/IPhantomFounders.sol";
import {IPhantomDexRouter} from "../../interfaces/level0/finance/routers/IPhantomDexRouter.sol";
import {IPhantomPayments} from "../../interfaces/level0/finance/IPhantomPayments.sol";
import {IPhantomStaking} from "../../interfaces/level0/staking/IPhantomStaking.sol";
import {IPhantomStorage} from "../../interfaces/storage/IPhantomStorage.sol";
import {IPhantomTreasury} from "../../interfaces/core/IPhantomTreasury.sol";
import {IPhantomTWAP} from "../../interfaces/core/IPhantomTWAP.sol";
import {IPhantomVault} from "../../interfaces/core/IPhantomVault.sol";
import {IPhantomStorageFactory} from "../../interfaces/storage/IPhantomStorageFactory.sol";
import {IPhantomStorageMixin} from "../../interfaces/mixins/IPhantomStorageMixin.sol";

/**
 * @title PhantomStorageMixin
 * @author PhantomDao Team
 * @notice A Mixin used to provide access to all Phantom contracts with a base set of behaviour
 */
contract PhantomStorageMixin is PhantomStorageKeys, ReentrancyGuard, IPhantomStorageMixin {
    //=================================================================================================================
    // State Variables
    //=================================================================================================================

    uint256 constant ONE_18D = 1e18;
    address internal _storageAddress;
    bytes32 phantomStorage = "phantomStorage";

    // uint256 public contractVersion;

    function PhantomStorage() internal view returns (IPhantomStorage) {
        return IPhantomStorage(_storageAddress);
    }

    // uint256 public contractVersion;

    //=================================================================================================================
    // Constructor
    //=================================================================================================================

    constructor(address storageAddress) {
        _storageAddress = storageAddress;
    }

    //=================================================================================================================
    // Internal Functons
    //=================================================================================================================

    function getContractAddressByName(bytes32 contractName, bytes32 storageContractName)
        internal
        view
        returns (address)
    {
        address contractAddress = PhantomStorage().getAddress(
            keccak256(abi.encodePacked(PhantomStorageKeys.security.addressof, contractName))
        );
        if (contractAddress == address(0x0))
            revert PhantomStorageMixin__ContractNotFoundByNameOrIsOutdated(contractName);
        return contractAddress;
    }

    function PHM() internal view returns (IPHM) {
        return IPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.phm)));
    }

    function sPHM() internal view returns (IsPHM) {
        return IsPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.sphm)));
    }

    function gPHM() internal view returns (IgPHM) {
        return IgPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.gphm)));
    }

    function aPHM() internal view returns (IaPHM) {
        return IaPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.aphm)));
    }

    function fPHM() internal view returns (IfPHM) {
        return IfPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.fphm)));
    }

    function PhantomTreasury() internal view returns (IPhantomTreasury) {
        return IPhantomTreasury(PhantomStorage().getAddress(keccak256(phantom.contracts.treasury)));
    }

    function PhantomDexRouter() internal view returns (IPhantomDexRouter) {
        return IPhantomDexRouter(PhantomStorage().getAddress(keccak256(phantom.contracts.dex_router)));
    }

    function PhantomStaking() internal view returns (IPhantomStaking) {
        return IPhantomStaking(PhantomStorage().getAddress(keccak256(phantom.contracts.staking)));
    }

    function PhantomAlphaSwap() internal view returns (IPhantomAlphaSwap) {
        return IPhantomAlphaSwap(PhantomStorage().getAddress(keccak256(phantom.contracts.alphaswap)));
    }

    function PhantomFounders() internal view returns (IPhantomFounders) {
        return IPhantomFounders(PhantomStorage().getAddress(keccak256(phantom.contracts.founders)));
    }

    function PhantomPayments() internal view returns (IPhantomPayments) {
        return IPhantomPayments(PhantomStorage().getAddress(keccak256(phantom.contracts.payments)));
    }

    function PhantomBonding() internal view returns (IPhantomBonding) {
        return IPhantomBonding(PhantomStorage().getAddress(keccak256(phantom.contracts.bonding)));
    }

    function PhantomVault() internal view returns (IPhantomVault) {
        return IPhantomVault(PhantomStorage().getAddress(keccak256(phantom.contracts.vault)));
    }

    function PhantomTWAP(address token) internal view returns (IPhantomTWAP) {
        // Returns the address of the desired oracle for a given bonding token
        return IPhantomTWAP(PhantomStorage().getAddress(keccak256(abi.encodePacked(phantom.contracts.twap, token))));
    }

    function PhantomBondPricing(address token) internal view returns (IPhantomTWAP) {
        // Returns the address of the desired oracle for a given bonding token
        return IPhantomTWAP(PhantomStorage().getAddress(keccak256(
            abi.encodePacked(abi.encodePacked(phantom.contracts.bondpricing, token))
        )));
    }

    function standardAccountKeys() internal view returns (bytes32[] memory) {
        bytes32[] memory keys = new bytes32[](2);
        keys[0] = keccak256(phantom.treasury.account_keys.reserves);
        keys[1] = keccak256(phantom.treasury.account_keys.venturecapital);
        return keys;
    }

    function standardAccountPercentages() internal pure returns (uint256[] memory) {
        uint256[] memory percentages = new uint256[](2);
        percentages[0] = ((0.9e18)); // reserves
        percentages[1] = ((0.10e18)); // venturecapital
        return percentages;
    }

    function reserveKey() internal view returns (bytes32[] memory) {
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256(phantom.treasury.account_keys.reserves);
        return keys;
    }

    function daoKey() internal view returns (bytes32[] memory) {
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256(phantom.treasury.account_keys.dao);
        return keys;
    }

    function percentage100() internal pure returns (uint256[] memory) {
        uint256[] memory percentages = new uint256[](1);
        percentages[0] = (1e18);
        return percentages;
    }

    //=================================================================================================================
    // Modifiers
    //=================================================================================================================

    modifier onlyRegisteredContracts() {
        bool storageInit = PhantomStorage().getDeployedStatus();
        if (storageInit == true) {
            // Make sure the access is permitted to only contracts registered with the network
            if (!PhantomStorage().getBool(keccak256(abi.encodePacked("phantom.contract.registered", msg.sender)))) {
                revert PhantomStorageMixin__ContractNotFoundByAddressOrIsOutdated(msg.sender);
            }
        } else {
            // tx.origin is only safe to use in this case for deployment since no external contracts are interacted with
            if (!(
                PhantomStorage().getBool(keccak256(abi.encodePacked("phantom.contract.registered", msg.sender))) ||
                    tx.origin == PhantomStorage().getGuardian()
            )) {
                revert PhantomStorageMixin__ContractNotFoundByAddressOrIsOutdated(msg.sender);
            }
        }
        _;
    }

    modifier onlyContract(
        bytes32 contractName,
        address inAddress,
        bytes32 storageContractName
    ) {
        if (
            inAddress !=
            PhantomStorage().getAddress(keccak256(abi.encodePacked(PhantomStorageKeys.security.name, contractName)))
        ) revert PhantomStorageMixin__ContractNotFoundByNameOrIsOutdated(contractName);
        _;
    }

    modifier onlyFromStorageGuardianOf(bytes32 storageContractName) {
        if (msg.sender != PhantomStorage().getGuardian()) revert PhantomStorageMixin__UserIsNotGuardian(msg.sender);
        _;
    }
}
