/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* Package Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomERC20} from "../../interfaces/core/erc20/IPhantomERC20.sol";
import {IPhantomVault} from "../../interfaces/core/IPhantomVault.sol";

/**
 * @title PhantomVault
 * @author PhantomDao Team
 * @notice The contract responsible for holding all ERC20 assets
 */
contract PhantomVault is PhantomStorageMixin, IPhantomVault {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    function withdraw(uint256 outAmount, address outToken) external override onlyRegisteredContracts {
        IERC20(outToken).safeTransfer(msg.sender, outAmount);
        emit PhantomVault_Withdrawal(msg.sender, outAmount, outToken);
    }

    function burn(uint256 burnAmount, address burnToken) external override onlyRegisteredContracts {
        IPhantomERC20(burnToken).burn(address(this), burnAmount);
        emit PhantomVault_Burned(msg.sender, burnAmount, burnToken);
    }
}
