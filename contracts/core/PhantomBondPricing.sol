/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;


import {IPhantomTWAP} from "../../interfaces/core/IPhantomTWAP.sol";
import {PhantomTWAP} from "./PhantomTWAP.sol";

interface IERC20 {
    function decimals() external view returns(uint8);
}

contract PhantomBondPricing is IPhantomTWAP {

    PhantomTWAP[] private twaps;

    address constant FRAX = 0xaf319E5789945197e365E7f7fbFc56B130523B33;
    
    constructor(address[] memory twaps_) public {
        for (uint i = 0; i < twaps.length; i++) {
            twaps.push(PhantomTWAP(twaps_[i]));
        }
    }

    function update() external override {
        for (uint i = 0; i < twaps.length; i++) {
            twaps[i].update();
        }
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view override returns (uint) {
        if (amountIn == 0) return 0;

        uint256 currentAmount = amountIn;
        address currentToken = token;

        // Pretty (super) Ghetto. Assumes there is matching sides for each step of the path. 
        // EG: gOMH/wFTM > wFTM/FRAX > FRAX/PHM (last pair must be FRAX/PHM)
        // TODO: unghetto this whole thing
        for (uint256 i; i < twaps.length; i++) {
            PhantomTWAP twap = twaps[i];
            uint256 outAmount = twap.consult(currentToken, currentAmount);
            address outToken = token == twap.token0()  ? twap.token1() : twap.token0();
            uint256 outDecimals = IERC20(outToken).decimals();

            // check decimal places
            currentAmount = outAmount * 10**(18 - outDecimals); // Pad to Match 18 FRAX decimals if needed
            currentToken = outToken;
        }

        require(currentToken == FRAX, "PhantomBondPricing: last pair must be FRAX/PHM");

        return twaps[twaps.length-1].consult(currentToken, currentAmount);
    }
}
