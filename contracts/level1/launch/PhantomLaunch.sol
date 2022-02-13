/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomLaunch} from "../../../interfaces/level1/launch/IPhantomLaunch.sol";
import {IPhantomAuctionClaim} from "../../../interfaces/level0/launch/IPhantomAuctionClaim.sol";

/**
 * @title PhantomLaunch
 * @author PhantomDao Team
 * @notice The dApp facing contract used for launch functions
 */
contract PhantomLaunch is PhantomStorageMixin, IPhantomLaunch {
    using PRBMathUD60x18 for uint256;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    function claimAPHM() external override nonReentrant {
        IPhantomAuctionClaim claim = IPhantomAuctionClaim(
            PhantomStorage().getAddress(keccak256(phantom.contracts.auctionclaim))
        );
        claim.purchase(msg.sender);
    }

    function swapAPHM() external override nonReentrant {
        PhantomAlphaSwap().swap(msg.sender);
    }

    function claimFPHM() external override nonReentrant {
        PhantomFounders().claim(msg.sender);
    }

    function exerciseFPHM() external override nonReentrant {
        PhantomFounders().exercise(msg.sender);
    }
}
