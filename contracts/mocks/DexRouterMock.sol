/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../mixins/PhantomStorageMixin.sol";

contract DexRouterMock is PhantomStorageMixin {
    using PRBMathUD60x18 for uint256;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    function getQuote(
        address dexRouter,
        address dexFactory,
        uint256 inAmount,
        address inToken,
        address outToken
    ) external view virtual returns (uint256) {
        return inAmount.div(5);
    }
}
