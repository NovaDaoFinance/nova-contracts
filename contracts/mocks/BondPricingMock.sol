/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {IPhantomTWAP} from "../../interfaces/core/IPhantomTWAP.sol";

contract BondPricingMock is IPhantomTWAP {
    using PRBMathUD60x18 for uint256;

    constructor() {
        return;
    }

    function update() external { return; }

    function consult(
        address token,
        uint256 inAmount
    ) external view virtual returns (uint256) {
        if (inAmount == 0) return 0;
        return inAmount.div(5);
    }
}
