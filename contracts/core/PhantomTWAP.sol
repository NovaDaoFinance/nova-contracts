/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import '../libs/FixedPoint.sol';

import '../libs/UniswapV2OracleLibrary.sol';
import {IUniswapV2Router02} from "../../../../interfaces/libs/IUniswapV2Router02.sol";

import {IPhantomTWAP} from "../../interfaces/core/IPhantomTWAP.sol";


contract PhantomTWAP is IPhantomTWAP {
    using FixedPoint for FixedPoint.uq144x112;
    using FixedPoint for FixedPoint.uq112x112;

    uint    public constant PERIOD = 30 minutes;

    IUniswapV2Pair immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    constructor(address pair_) public {
        pair = IUniswapV2Pair(pair_);
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'PhantomTWAP: NO_RESERVES'); // ensure that there's liquidity in the pair
    }

    function update() external override {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
            // ensure that at least one full period has passed since the last update
            if (timeElapsed >= PERIOD) return;

            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
            price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

            price0CumulativeLast = price0Cumulative;
            price1CumulativeLast = price1Cumulative;
            blockTimestampLast = blockTimestamp;
        }
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external override view returns (uint amountOut) {
        if (amountIn == 0) return 0;

        FixedPoint.uq112x112 memory price0Average_ = price0Average;
        FixedPoint.uq112x112 memory price1Average_ = price1Average;
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));

        // Protect against stale price
        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
            // ensure that at least one full period has passed since the last update
            if (timeElapsed < PERIOD) {

                // overflow is desired, casting never truncates
                // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
                price0Average_ = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
                price1Average_ = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
            }
        }

        if (token == token0) {
            amountOut = price0Average_.mul(amountIn).decode144();
        } else {
            require(token == token1, 'PhantomTWAP: INVALID_TOKEN');
            amountOut = price1Average_.mul(amountIn).decode144();
        }
    }
}