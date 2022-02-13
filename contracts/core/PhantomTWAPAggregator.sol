/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Interface Imports */
import {IPhantomTWAPAggregator} from "../../interfaces/core/IPhantomTWAPAggregator.sol";
import {IPhantomTWAP} from "../../interfaces/core/IPhantomTWAP.sol";

interface IERC20 {
    function decimals() external view returns(uint8);
}

contract PhantomTWAPAggregator is IPhantomTWAPAggregator {

    IPhantomTWAP[] private twaps;

    address constant FRAX = 0xaf319E5789945197e365E7f7fbFc56B130523B33;
    
    constructor (address[] memory twaps_) {
        for (uint i = 0; i < twaps.length; i++) {
            twaps.push(IPhantomTWAP(twaps_[i]));
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
        uint8 currentDecimals;

        // Pretty (super) Ghetto. Assumes there is matching sides for each step of the path. 
        // EG: gOMH/wFTM > wFTM/FRAX > FRAX/PHM (last pair must be FRAX/PHM)
        // TODO: unghetto this whole thing
        for (uint256 i; i < twaps.length; i++) {
            IPhantomTWAP twap = twaps[i];
            address outToken = token == twap.token0() ? twap.token1() : twap.token0();

            currentAmount = twap.consult(currentToken, currentAmount);
            currentDecimals = IERC20(outToken).decimals();
            currentToken = outToken;
        }

        require(currentToken == FRAX, "PhantomBondPricing: last pair must be FRAX/PHM");

        return twaps[twaps.length-1].consult(currentToken, currentAmount);
    }
}
