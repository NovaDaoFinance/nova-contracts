/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* Package Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomERC20} from "../../../interfaces/core/erc20/IPhantomERC20.sol";
import {IPhantomPayments} from "../../../interfaces/level0/finance/IPhantomPayments.sol";
import {IPhantomTreasury} from "../../../interfaces/core/IPhantomTreasury.sol";

/**
 * @title PhantomPayments
 * @author PhantomDao Team
 * @notice The contract responsible for holding all ERC20 assets
 */
contract PhantomPayments is PhantomStorageMixin, IPhantomPayments {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    uint256 SECONDS_PER_YEAR = 31_536_000;

    mapping(address => uint256) yearlySalary;
    mapping(address => address) paymentToken;
    mapping(address => uint256) lastClaimTime;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    //=================================================================================================================
    // Public Functions
    //=================================================================================================================

    function deleteEmployee(address employee) public override onlyRegisteredContracts {
        delete yearlySalary[employee];
        delete paymentToken[employee];
        delete lastClaimTime[employee];
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    function addEmployee(
        address employee,
        uint256 salary,
        address inToken
    ) external override onlyRegisteredContracts {
        yearlySalary[employee] = salary;
        paymentToken[employee] = inToken;
        lastClaimTime[employee] = block.timestamp;
    }

    function modifyEmployee(
        address employee,
        address newToken,
        uint256 newSalary
    ) external override onlyRegisteredContracts {
        if (newSalary != 0) yearlySalary[employee] = newSalary;
        if (newToken != address(0)) paymentToken[employee] = newToken;
    }

    function changeEmployeeAddress(address newAddress) external override onlyRegisteredContracts {
        yearlySalary[newAddress] = yearlySalary[msg.sender];
        paymentToken[newAddress] = paymentToken[msg.sender];
        lastClaimTime[newAddress] = lastClaimTime[msg.sender];
        deleteEmployee(msg.sender);
    }

    function claimSalary() external override {
        uint256 payment = (yearlySalary[msg.sender] / SECONDS_PER_YEAR) * (block.timestamp - lastClaimTime[msg.sender]);
        lastClaimTime[msg.sender] = block.timestamp;
        if (payment == 0) revert();
        PhantomTreasury().swap(msg.sender, (0), address(0), payment, paymentToken[msg.sender], daoKey(), percentage100());
    }
}
