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
import {IPhantomAlphaSwap} from "../../../interfaces/level0/launch/IPhantomAlphaSwap.sol";

/**
 * @title PhantomAlphaSwap
 * @author PhantomDao Team
 * @notice This contract given people PHM in return for their aPHM. In reality,
 * aPHM is being issued on the eth chain, so this contract is just a list of
 * addresses and how much PHM they are entitled to
 */
contract PhantomAlphaSwap is IPhantomAlphaSwap, PhantomStorageMixin {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    //=================================================================================================================
    // External Functionss
    //=================================================================================================================

    /**
     * @dev Burn aPHM for PHM on a 1:1 basis
     */
    function swap(address claimer) external override onlyRegisteredContracts nonReentrant {
        require(aPHM().balanceOf(claimer) > 0, "PhantomAlphaSwap: no aPHM to swap");

        PhantomTreasury().swapBurnMint(
            claimer,
            aPHM().balanceOf(claimer),
            address(aPHM()),
            aPHM().balanceOf(claimer),
            address(PHM())
        );
    }
}
