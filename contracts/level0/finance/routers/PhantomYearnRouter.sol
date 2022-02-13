/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../../mixins/PhantomStorageMixin.sol";

/**
 * @title PhantomExchange
 * @author PhantomDao Team
 * @notice How the Phantom Network connects to Defi tools
 */
contract PhantomYearnRouter is PhantomStorageMixin {
    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }
}
