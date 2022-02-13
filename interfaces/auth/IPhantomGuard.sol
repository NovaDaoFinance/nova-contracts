/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomVault
 * @author PhantomDao Team
 * @notice The Interface for IPhantomVault
 */
interface IPhantomGuard {

    //=================================================================================================================
    // Events
    //=================================================================================================================

    event LogPermit(bytes32 indexed src, bytes32 indexed dst, bytes32 indexed sig);
    event LogForbid(bytes32 indexed src, bytes32 indexed dst, bytes32 indexed sig);

    //=================================================================================================================
    // Functions
    //=================================================================================================================

    function permit(bytes32 src, bytes32 dst, bytes32 sig) external;
    function permit(address src, address dst, bytes4 sig) external;
    function forbid(bytes32 src, bytes32 dst, bytes32 sig) external;
    function forbid(address src, address dst, bytes4 sig) external;
}