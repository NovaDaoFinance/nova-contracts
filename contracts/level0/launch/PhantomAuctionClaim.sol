/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IaPHM} from "../../../interfaces/core/erc20/IaPHM.sol";
import {IPhantomAuctionClaim} from "../../../interfaces/level0/launch/IPhantomAuctionClaim.sol";

/**
 * @title PhantomWhitelist
 * @author PhantomDao Team
 * @notice Claim allowed alotment of aPHM for 50 frax
 */
contract PhantomAuctionClaim is PhantomStorageMixin, IPhantomAuctionClaim {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IaPHM;

    uint256 internal constant PRICE = 50e18;
    address internal _token;
    mapping(address => uint256) internal allotments;

    constructor(address storageFactoryAddress, address token) PhantomStorageMixin(storageFactoryAddress) {
        _token = token;
        return;
    }

    //=================================================================================================================
    // External Functionss
    //=================================================================================================================

    /**
     * @dev register founder as having a claim to amount of FRAX (IE aPHM * PRICE)
     */
    function registerAllotment(address claimer, uint256 amount) external override onlyRegisteredContracts nonReentrant {
        allotments[claimer] += amount;
    }

    /**
     * @dev Issue claimer with aPHM tokens in return for frax
     */
    function purchase(address claimer) external override onlyRegisteredContracts nonReentrant {
        uint256 amount = allotments[claimer];
        require(amount > 0, "PhantomAuctionClaim: No aPHM tokens allocated");

        PhantomTreasury().swapMint(
            claimer,
            amount,
            _token,
            amount.div(PRICE),
            address(aPHM()),
            standardAccountKeys(),
            standardAccountPercentages()
        );
        delete allotments[claimer];
    }


    //=================================================================================================================
    // Public Functionss
    //=================================================================================================================

    function remainingAllotment(address claimer) public view override returns (uint256) {
        return allotments[claimer].div(PRICE);
    }
}