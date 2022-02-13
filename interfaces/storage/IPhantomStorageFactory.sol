/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Interface Imports */
import {IPhantomStorage} from "./IPhantomStorage.sol";

/**
 * @title PhantomStorageFactory
 * @author PhantomDao Team
 * @notice Interface for PhantomStorageFactory
 */

interface IPhantomStorageFactory {
    //=================================================================================================================
    // Errors
    //=================================================================================================================

    error PhantomStorageFactory_ContractAlreadyExists(bytes32 inContractName);
    error PhantomStorageFactory_ContractDoesNotExist(bytes32 inContractName);

    //=================================================================================================================
    // Mutators
    //=================================================================================================================

    function deployStorageContract(bytes32 inContractName) external returns (IPhantomStorage);
    function removeStorageContract(bytes32 inContractName) external returns (bool);

    //=================================================================================================================
    // Accessors
    //=================================================================================================================

    function getStorageContractByName(bytes32 inContractName) external view returns (IPhantomStorage);
}
