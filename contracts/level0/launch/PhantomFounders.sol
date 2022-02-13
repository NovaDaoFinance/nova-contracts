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
import {IPhantomFounders} from "../../../interfaces/level0/launch/IPhantomFounders.sol";

/**
 * @title PhantomFounders
 * @author PhantomDao Team
 * @notice This contract deals with everything fPHM related, including vesting and claiming
 */
contract PhantomFounders is PhantomStorageMixin, IPhantomFounders {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant SECONDS_PER_YEAR = 31_536_000;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    //=================================================================================================================
    // External Functionss
    //=================================================================================================================

    /**
     * @dev start the vesting clock. This is a one time operation.
     */
    function startVesting() external override onlyRegisteredContracts {
        require(vestingStarts() == 0, "Vesting already started");
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.founder.vestingStarts)), block.timestamp);
    }

    /**
     * @dev register founder as having a claim to amount of founder tokens
     */
    function registerFounder(address founder, uint256 amount) external override onlyRegisteredContracts nonReentrant {
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.founder.claims.allocation, founder)), amount);
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.founder.claims.initialAmount, founder)), amount);
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.founder.claims.remainingAmount, founder)), amount);
    }

    /**
     * @dev Issue founder fPHM tokens if they have a valid claim to them.
     */
    function claim(address founder) external override onlyRegisteredContracts nonReentrant {
        require(fPHM().balanceOf(founder) == 0, "fPHM tokens already allocated to founder");

        uint256 amount = PhantomStorage().getUint(
            keccak256(abi.encodePacked(phantom.founder.claims.allocation, founder))
        );
        require(amount > 0, "No fPHM tokens allocated to founder");

        fPHM().mint(founder, amount);
        PhantomStorage().subUint(keccak256(abi.encodePacked(phantom.founder.claims.allocation, founder)), amount);
    }

    /**
     * @dev swap founder's vested fPHM for gPHM
     */
    function exercise(address founder) external override onlyRegisteredContracts nonReentrant {
        require(fPHM().balanceOf(founder) > 0, "Founder has no fPHM tokens");

        // Get outstanding balances
        uint256 unclaimedAmount = unclaimedBalance(founder);

        require(unclaimedAmount > 0, "No vested tokens to exercise");

        // Burn and mint
        PhantomTreasury().swapBurnMint(founder, unclaimedAmount, address(fPHM()), unclaimedAmount, address(gPHM()));

        // Update remaining amount
        PhantomStorage().subUint(
            keccak256(abi.encodePacked(phantom.founder.claims.remainingAmount, founder)),
            unclaimedAmount
        );

        // Record this claim
        PhantomStorage().setUint(
            keccak256(abi.encodePacked(phantom.founder.claims.lastClaim, founder)),
            block.timestamp
        );
    }

    //=================================================================================================================
    // Public Functionss
    //=================================================================================================================

    function vestingStarts() public view returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.founder.vestingStarts)));
    }

    function remainingAllocation(address founder) public view returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.founder.claims.allocation, founder)));
    }

    /**
     * @dev get the balance of unclaimed vested tokens for founder
     */
    function unclaimedBalance(address founder) public view returns (uint256) {
        uint256 initialAmount = PhantomStorage().getUint(
            keccak256(abi.encodePacked(phantom.founder.claims.initialAmount, founder))
        );
        if (initialAmount == 0) return 0;
        if (vestingStarts() == 0) return 0;

        uint256 remainingAmount = PhantomStorage().getUint(
            keccak256(abi.encodePacked(phantom.founder.claims.remainingAmount, founder))
        );
        if (remainingAmount == 0) return 0;

        // Do the math to figure out how many tokens have vested.
        // 25% vest immediately, remaining 75% vest over the next 12 months
        uint256 vested = initialAmount.div(4 * 1e18) +
            initialAmount.div(4 * 1e18).mul(3 * 1e18).mul(
                ((block.timestamp - vestingStarts()) * 1e18).div(SECONDS_PER_YEAR * 1e18)
            );
        if (vested > initialAmount) vested = initialAmount;
        return vested - (initialAmount - remainingAmount);
    }
}
