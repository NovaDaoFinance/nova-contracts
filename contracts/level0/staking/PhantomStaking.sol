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
import {IPhantomStaking} from "../../../interfaces/level0/staking/IPhantomStaking.sol";

/**
 * @title PhantomStaking
 * @author PhantomDao Team
 * @notice The contract that handles staking sPHM
 */
contract PhantomStaking is PhantomStorageMixin, IPhantomStaking {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    constructor(address storageFactoryAddress) PhantomStorageMixin(storageFactoryAddress) {
        return;
    }

    //=================================================================================================================
    // External Functionss
    //=================================================================================================================

    function initializeRebasing() external onlyRegisteredContracts {
        // Set rebase state
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.staking.rebaseCounter)), 1);
        PhantomStorage().setUint(
            keccak256(abi.encodePacked(phantom.staking.nextRebaseDeadline)),
            block.timestamp + sPHM().secondsPerCompoundingPeriod()
        );
    }

    function stake(address inStaker, uint256 inAmount) external override onlyRegisteredContracts nonReentrant {
        attemptRebase();
        // Burn the PHM and mint sPHM
        PhantomTreasury().swapBurnMint(inStaker, inAmount, address(PHM()), inAmount, address(sPHM()));
    }

    function unstake(address inUnstaker, uint256 inAmount) external override onlyRegisteredContracts nonReentrant {
        attemptRebase();
        // Burn the sPHM and mint PHM
        PhantomTreasury().swapBurnMint(inUnstaker, inAmount, address(sPHM()), inAmount, address(PHM()));
    }

    /**
     * @notice convert _amount of sPHM into gPHM
     * @param toUser address who is to own the gPHM?
     * @param amount uint how much sPHM to wrap
     * @return gBalance uint amount of gPHM minted
     */
    function wrap(address toUser, uint256 amount)
        external
        override
        onlyRegisteredContracts
        nonReentrant
        returns (uint256 gBalance)
    {
        attemptRebase();
        // Burn the sPHM and mint gPHM
        PhantomTreasury().swapBurnMint(toUser, amount, address(sPHM()), gPHM().balanceFromPHM(amount), address(gPHM()));
    }

    /**
     * @notice convert amount of gPHM into sPHM
     * @param toUser address who is to own the sPHM?
     * @param amount uint how much gPHM to unwrap
     * @return sBalance uint amount of sPHM transfered
     */
    function unwrap(address toUser, uint256 amount)
        external
        override
        onlyRegisteredContracts
        nonReentrant
        returns (uint256 sBalance)
    {
        attemptRebase();
        // Burn the gPHM and mint sPHM
        PhantomTreasury().swapBurnMint(toUser, amount, address(gPHM()), gPHM().balanceToPHM(amount), address(sPHM()));
    }

    //=================================================================================================================
    // Public Functions
    //=================================================================================================================

    /**
     * @dev when is the next rebase?
     */
    function nextRebaseDeadline() public view returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.staking.nextRebaseDeadline)));
    }

    /**
     * @dev when is the next rebase?
     */
    function rebaseCounter() public view returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.staking.rebaseCounter)));
    }

    /**
     * @dev Trigger a rebase if it's time to do so.
     */
    function attemptRebase() public override onlyRegisteredContracts {
        uint256 nextRebaseDeadline_ = nextRebaseDeadline();

        require(nextRebaseDeadline_ > 0, "Staking hasn't been initalised");

        if (nextRebaseDeadline_ <= block.timestamp) {
            // Do the rebase
            sPHM().doRebase(rebaseCounter());

            // Set state for next rebase
            PhantomStorage().addUint(keccak256(abi.encodePacked(phantom.staking.rebaseCounter)), 1);
            PhantomStorage().addUint(
                keccak256(abi.encodePacked(phantom.staking.nextRebaseDeadline)),
                sPHM().secondsPerCompoundingPeriod()
            );
        }
    }
}
