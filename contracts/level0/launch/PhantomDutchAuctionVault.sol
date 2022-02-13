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
import {IPhantomDutchAuctionVault} from "../../../interfaces/level0/launch/IPhantomDutchAuctionVault.sol";

/**
 * @title PhantomDutchAuctionVault
 * @author PhantomDao Team
 * @notice This contract given people PHM in return for their aPHM. In reality,
 * aPHM is being issued on the eth chain, so this contract is just a list of
 * addresses and how much PHM they are entitled to
 */
contract PhantomDutchAuctionVault is PhantomStorageMixin, IPhantomDutchAuctionVault {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    address private immutable _token;

    constructor(address storageFactoryAddress, address token) PhantomStorageMixin(storageFactoryAddress) {
        _token = token;
    }

    //=================================================================================================================
    // External Functionss
    //=================================================================================================================

    /**
     * @dev Transfer full balance of token to the treasury
     */
    function transferToTreasury() external override onlyRegisteredContracts nonReentrant {
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) > 0, "Balance is 0");
        token.approve(address(PhantomTreasury()), token.balanceOf(address(this)));
        PhantomTreasury().swap(
            address(this),
            token.balanceOf(address(this)),
            _token,
            (0),
            address(0),
            standardAccountKeys(),
            standardAccountPercentages()
        );
    }
}
