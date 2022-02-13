/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomFinance} from "../../../interfaces/level1/finance/IPhantomFinance.sol";
import {IPhantomERC20} from "../../../interfaces/core/erc20/IPhantomERC20.sol";

/**
 * @title PhantomFinance
 * @author PhantomDao Team
 * @notice The dApp facing contract used for finance functions
 */
contract PhantomFinance is PhantomStorageMixin, IPhantomFinance {
    using PRBMathUD60x18 for uint256;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    function stake(uint256 inAmount) external override nonReentrant {
        PhantomStaking().stake(msg.sender, inAmount);
    }

    function unstake(uint256 inAmount) external override nonReentrant {
        PhantomStaking().unstake(msg.sender, inAmount);
    }

    function wrap(uint256 inAmount) external override nonReentrant {
        PhantomStaking().wrap(msg.sender, inAmount);
    }

    function unwrap(uint256 inAmount) external override nonReentrant {
        PhantomStaking().unwrap(msg.sender, inAmount);
    }

    function bond(
        uint256 inAmount,
        address inToken,
        bytes calldata inBondType
    ) external override nonReentrant {
        PhantomBonding().createBond(msg.sender, inAmount, inToken, inBondType);
    }

    function donate(
        uint256 inAmount,
        address inToken
    ) external override nonReentrant {
        PhantomTreasury().swap(
            msg.sender,
            inAmount,
            inToken,
            0,
            address(0),
            standardAccountKeys(),
            standardAccountPercentages()
        );
    }
}
