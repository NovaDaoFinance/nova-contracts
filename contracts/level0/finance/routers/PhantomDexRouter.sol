/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";

/* Package Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../../../../interfaces/libs/IUniswapV2Router02.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomDexRouter} from "../../../../interfaces/level0/finance/routers/IPhantomDexRouter.sol";

/**
 * @title PhantomDexRouter
 * @author PhantomDao Team
 * @notice Communicate with a UniSwap dex
 */
contract PhantomDexRouter is PhantomStorageMixin, IPhantomDexRouter {
    using PRBMathUD60x18 for uint256;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    function getQuote(
        address dexRouter,
        address dexFactory,
        uint256 inAmount,
        address inToken,
        address outToken
    ) external view virtual override returns (uint256) {
        (uint256 inReserves, uint256 outReserves) = getReserves(dexFactory, inToken, outToken);
        uint256 quote = IUniswapV2Router02(dexRouter).quote(inAmount, inReserves, outReserves);
        return (quote);
    }

    function swapReceiveMinimum(
        address dexRouter,
        uint256 inAmount,
        uint256 minOutAmount,
        address[] memory path,
        uint256 deadline,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external virtual override onlyRegisteredContracts {
        preSwap(inAmount, path[0], keys, percentages);
        IUniswapV2Router02(dexRouter).swapExactTokensForTokens(
            inAmount, 
            minOutAmount, 
            path,
            address(this), 
            deadline
        );
        postSwap(path[0], path[path.length - 1], keys, percentages);
    }

    function swapSpendMaximum(
        address dexRouter,
        uint256 outAmount,
        uint256 maxInAmount,
        address[] memory path,
        uint256 deadline,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external virtual override onlyRegisteredContracts {
        preSwap(maxInAmount, path[0], keys, percentages);
        IUniswapV2Router02(dexRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            outAmount,
            maxInAmount,
            path,
            address(this),
            deadline
        );
        postSwap(path[0], path[path.length - 1], keys, percentages);
    }

    //=================================================================================================================
    // Internal Functions
    //=================================================================================================================

    function preSwap(
        uint256 requiredFunds,
        address requiredToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) internal {
        PhantomTreasury().swap(address(this), 0, address(0), requiredFunds, requiredToken, keys, percentages);
    }

    function postSwap(
        address sentToken,
        address receivedToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) internal {
        uint256 sentBalance = IERC20(sentToken).balanceOf(address(this));
        uint256 receivedBalance = IERC20(receivedToken).balanceOf(address(this));

        if (sentBalance != 0) {
            IERC20(sentToken).approve(address(PhantomTreasury()), sentBalance);
            PhantomTreasury().swap(
                address(this),
                sentBalance,
                address(PhantomTreasury()),
                0,
                address(0),
                keys,
                percentages
            );
        }

        if (receivedBalance != 0) {
            IERC20(receivedToken).approve(address(PhantomTreasury()), receivedBalance);
            PhantomTreasury().swap(
                address(this),
                receivedBalance,
                address(PhantomTreasury()),
                0,
                address(0),
                keys,
                percentages
            );
        }
    }

    //=================================================================================================================
    // UniswapV2 Library
    //=================================================================================================================

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }
}
