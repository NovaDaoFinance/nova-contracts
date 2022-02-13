/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Imports*/
import {PhantomStorageKeys} from "./PhantomStorageKeys.sol";

/* Internal Interface Imports */
import {IPhantomStorage} from "../../interfaces/storage/IPhantomStorage.sol";

/**
 * @title PhantomStorage()
 * @author PhantomDao Team
 * @notice The Eternal Storage contract powering the Phantom Network
 */
contract PhantomStorage is PhantomStorageKeys, IPhantomStorage {
    //=================================================================================================================
    // Storage Maps
    //=================================================================================================================

    mapping(bytes32 => string) private stringStorage;
    mapping(bytes32 => bytes) private bytesStorage;
    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => int256) private intStorage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private booleanStorage;
    mapping(bytes32 => bytes32) private bytes32Storage;

    mapping(bytes32 => string[]) private stringArrayStorage;
    mapping(bytes32 => bytes[]) private bytesArrayStorage;
    mapping(bytes32 => uint256[]) private uintArrayStorage;
    mapping(bytes32 => int256[]) private intArrayStorage;
    mapping(bytes32 => address[]) private addressArrayStorage;
    mapping(bytes32 => bool[]) private booleanArrayStorage;
    mapping(bytes32 => bytes32[]) private bytes32ArrayStorage;

    //=================================================================================================================
    // State Variables
    //=================================================================================================================

    address storageGuardian;
    address newStorageGuardian;
    bool storageInit = false;

    //=================================================================================================================
    // Constructor
    //=================================================================================================================

    constructor() {
        storageGuardian = msg.sender;
    }

    //=================================================================================================================
    // Modifiers
    //=================================================================================================================

    modifier onlyRegisteredContracts() {
        if (storageInit == true) {
            // Make sure the access is permitted to only contracts registered with the network
            if (!booleanStorage[keccak256(abi.encodePacked("phantom.contract.registered", msg.sender))]) {
                revert PhantomStorage__ContractNotRegistered(msg.sender);
            }
        } else {
            // tx.origin is only safe to use in this case for deployment since no external contracts are interacted with
            if (
                !(booleanStorage[keccak256(abi.encodePacked("phantom.contract.registered", msg.sender))] ||
                    tx.origin == storageGuardian)
            ) revert PhantomStorage__ContractNotRegistered(msg.sender);
        }
        _;
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    function registerContract(bytes calldata contractName, address contractAddress)
        external
        override
        onlyRegisteredContracts
    {
        booleanStorage[keccak256(abi.encodePacked("phantom.contract.registered", contractAddress))] = true;
        addressStorage[keccak256(abi.encodePacked(contractName))] = contractAddress;
    }

    function unregisterContract(bytes calldata contractName) external override onlyRegisteredContracts {
        address contractAddress = addressStorage[keccak256(abi.encodePacked(contractName))];
        delete booleanStorage[keccak256(abi.encodePacked("phantom.contract.registered", contractAddress))];
        delete addressStorage[keccak256(abi.encodePacked(contractName))];
    }

    function getGuardian() external view override returns (address) {
        return storageGuardian;
    }

    function sendGuardianInvitation(address _newAddress) external override {
        if (msg.sender != storageGuardian) revert PhantomStorage__NotStorageGuardian(msg.sender);
        newStorageGuardian = _newAddress;
    }

    function acceptGuardianInvitation() external override {
        if (msg.sender != newStorageGuardian) revert PhantomStorage__NoGuardianInvitation(msg.sender);
        address oldGuardian = storageGuardian;
        storageGuardian = newStorageGuardian;
        delete newStorageGuardian;
        emit GuardianChanged(oldGuardian, storageGuardian);
    }

    function getDeployedStatus() external view override returns (bool) {
        return storageInit;
    }

    function setDeployedStatus() external {
        if (msg.sender != storageGuardian) revert PhantomStorage__NotStorageGuardian(msg.sender);
        storageInit = true;
    }

    //=================================================================================================================
    // Accessors
    //=================================================================================================================

    /// @param _key The key for the record
    function getAddress(bytes32 _key) external view override returns (address r) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view override returns (uint256 r) {
        return uintStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) external view override returns (string memory) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) external view override returns (bytes memory) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view override returns (bool r) {
        return booleanStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) external view override returns (int256 r) {
        return intStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32(bytes32 _key) external view override returns (bytes32 r) {
        return bytes32Storage[_key];
    }

    //=================================================================================================================
    // Accessors Arrays
    //=================================================================================================================

    /// @param _key The key for the record
    function getAddressArray(bytes32 _key) external view override returns (address[] memory r) {
        return addressArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getUintArray(bytes32 _key) external view override returns (uint256[] memory r) {
        return uintArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getStringArray(bytes32 _key) external view override returns (string[] memory) {
        return stringArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getBytesArray(bytes32 _key) external view override returns (bytes[] memory) {
        return bytesArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getBoolArray(bytes32 _key) external view override returns (bool[] memory r) {
        return booleanArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getIntArray(bytes32 _key) external view override returns (int256[] memory r) {
        return intArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32Array(bytes32 _key) external view override returns (bytes32[] memory r) {
        return bytes32ArrayStorage[_key];
    }

    //=================================================================================================================
    // Mutators
    //=================================================================================================================

    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) external override onlyRegisteredContracts {
        addressStorage[_key] = _value;
    }

    // @param _key The key for the record
    function setUint(bytes32 _key, uint256 _value) external override onlyRegisteredContracts {
        uintStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string calldata _value) external override onlyRegisteredContracts {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes calldata _value) external override onlyRegisteredContracts {
        bytesStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) external override onlyRegisteredContracts {
        booleanStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setInt(bytes32 _key, int256 _value) external override onlyRegisteredContracts {
        intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32(bytes32 _key, bytes32 _value) external override onlyRegisteredContracts {
        bytes32Storage[_key] = _value;
    }

    //=================================================================================================================
    // Mutators Arrays
    //=================================================================================================================

    /// @param _key The key for the record
    function setAddressArray(bytes32 _key, address[] memory _value) external override onlyRegisteredContracts {
        addressArrayStorage[_key] = _value;
    }

    // @param _key The key for the record
    function setUintArray(bytes32 _key, uint256[] memory _value) external override onlyRegisteredContracts {
        uintArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setStringArray(bytes32 _key, string[] memory _value) external override onlyRegisteredContracts {
        stringArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytesArray(bytes32 _key, bytes[] memory _value) external override onlyRegisteredContracts {
        bytesArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBoolArray(bytes32 _key, bool[] memory _value) external override onlyRegisteredContracts {
        booleanArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setIntArray(bytes32 _key, int256[] memory _value) external override onlyRegisteredContracts {
        intArrayStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32Array(bytes32 _key, bytes32[] memory _value) external override onlyRegisteredContracts {
        bytes32ArrayStorage[_key] = _value;
    }

    //=================================================================================================================
    // Deletion
    //=================================================================================================================

    /// @param _key The key for the record
    function deleteBytes32(bytes32 _key) external override onlyRegisteredContracts {
        delete bytes32Storage[_key];
    }

    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) external override onlyRegisteredContracts {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) external override onlyRegisteredContracts {
        delete uintStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) external override onlyRegisteredContracts {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) external override onlyRegisteredContracts {
        delete bytesStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) external override onlyRegisteredContracts {
        delete booleanStorage[_key];
    }

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) external override onlyRegisteredContracts {
        delete intStorage[_key];
    }

    //=================================================================================================================
    // Deletion Arrays
    //=================================================================================================================

    /// @param _key The key for the record
    function deleteBytes32Array(bytes32 _key) external override onlyRegisteredContracts {
        delete bytes32ArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteAddressArray(bytes32 _key) external override onlyRegisteredContracts {
        delete addressArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUintArray(bytes32 _key) external override onlyRegisteredContracts {
        delete uintArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteStringArray(bytes32 _key) external override onlyRegisteredContracts {
        delete stringArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytesArray(bytes32 _key) external override onlyRegisteredContracts {
        delete bytesArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBoolArray(bytes32 _key) external override onlyRegisteredContracts {
        delete booleanArrayStorage[_key];
    }

    /// @param _key The key for the record
    function deleteIntArray(bytes32 _key) external override onlyRegisteredContracts {
        delete intArrayStorage[_key];
    }

    //=================================================================================================================
    // Arithmetic
    //=================================================================================================================

    /// @param _key The key for the record
    /// @param _amount An amount to add to the record's value
    function addUint(bytes32 _key, uint256 _amount) external override onlyRegisteredContracts {
        uintStorage[_key] = uintStorage[_key] + _amount;
    }

    /// @param _key The key for the record
    /// @param _amount An amount to subtract from the record's value
    function subUint(bytes32 _key, uint256 _amount) external override onlyRegisteredContracts {
        uintStorage[_key] = uintStorage[_key] - _amount;
    }
}
