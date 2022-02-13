/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomStorage
 * @author PhantomDao Team
 * @notice The Interface of PhantomStorage()
 */
interface IPhantomStorage {

    //=================================================================================================================
    // Errors
    //=================================================================================================================
    
    error PhantomStorage__ContractNotRegistered(address contractAddress);
    error PhantomStorage__NotStorageGuardian(address user);
    error PhantomStorage__NoGuardianInvitation(address user);

    //=================================================================================================================
    // Events
    //=================================================================================================================

    event ContractRegistered(address contractRegistered);
    event GuardianChanged(address oldStorageGuardian, address newStorageGuardian);

    //=================================================================================================================
    // Deployment Status
    //=================================================================================================================

    function getDeployedStatus() external view returns (bool);
    function registerContract(bytes calldata contractName, address contractAddress) external;
    function unregisterContract(bytes calldata contractName) external;

    //=================================================================================================================
    // Guardian
    //=================================================================================================================

    function getGuardian() external view returns(address);
    function sendGuardianInvitation(address _newAddress) external;
    function acceptGuardianInvitation() external;

    //=================================================================================================================
    // Accessors
    //=================================================================================================================

    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    function getAddressArray(bytes32 _key) external view returns (address[] memory);
    function getUintArray(bytes32 _key) external view returns (uint[] memory);
    function getStringArray(bytes32 _key) external view returns (string[] memory);
    function getBytesArray(bytes32 _key) external view returns (bytes[] memory);
    function getBoolArray(bytes32 _key) external view returns (bool[] memory);
    function getIntArray(bytes32 _key) external view returns (int[] memory);
    function getBytes32Array(bytes32 _key) external view returns (bytes32[] memory);

    //=================================================================================================================
    // Mutators
    //=================================================================================================================
    
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    function setAddressArray(bytes32 _key, address[] memory _value) external;
    function setUintArray(bytes32 _key, uint[] memory _value) external;
    function setStringArray(bytes32 _key, string[] memory _value) external;
    function setBytesArray(bytes32 _key, bytes[] memory _value) external;
    function setBoolArray(bytes32 _key, bool[] memory _value) external;
    function setIntArray(bytes32 _key, int[] memory _value) external;
    function setBytes32Array(bytes32 _key, bytes32[] memory _value) external;

    //=================================================================================================================
    // Deletion
    //=================================================================================================================

    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

    function deleteAddressArray(bytes32 _key) external;
    function deleteUintArray(bytes32 _key) external;
    function deleteStringArray(bytes32 _key) external;
    function deleteBytesArray(bytes32 _key) external;
    function deleteBoolArray(bytes32 _key) external;
    function deleteIntArray(bytes32 _key) external;
    function deleteBytes32Array(bytes32 _key) external;

    //=================================================================================================================
    // Arithmetic
    //=================================================================================================================

    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
}