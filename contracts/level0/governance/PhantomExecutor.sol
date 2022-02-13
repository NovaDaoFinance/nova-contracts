/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomExecutor} from "../../../interfaces/level0/governance/IPhantomExecutor.sol";

/**
 * @title PhantomGovernor
 * @author PhantomDao Team
 * @notice The Governor of the PhantomNetwork
 */
contract PhantomExecutor is TimelockController, PhantomStorageMixin, IPhantomExecutor {
    constructor(
        address storageFactoryAddress,
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }
}
