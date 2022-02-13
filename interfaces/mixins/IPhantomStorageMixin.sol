/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/** 
 * @title IPhantomStorageMixin
 * @author PhantomDao Team
 * @notice Interface of PhantomStorageMixin
 */
interface IPhantomStorageMixin {

    //=================================================================================================================
    // Errors
    //=================================================================================================================
    
    error PhantomStorageMixin__ContractNotFoundByAddressOrIsOutdated(address contractAddress);
    error PhantomStorageMixin__ContractNotFoundByNameOrIsOutdated(bytes32 contractName);
    error PhantomStorageMixin__UserIsNotGuardian(address user);
        

}