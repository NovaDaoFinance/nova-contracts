/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomPayments
 * @author PhantomDao Team
 * @notice The Inteface for PhantomPayments
 */
interface IPhantomPayments {
    function deleteEmployee(address employee) external;

    function addEmployee(
        address employee,
        uint256 salary,
        address inToken
    ) external;

    function modifyEmployee(
        address employee,
        address newToken,
        uint256 newSalary
    ) external;

    function changeEmployeeAddress(address newAddress) external;

    function claimSalary() external;
}