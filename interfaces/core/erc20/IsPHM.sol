/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Interface Import */
import {IPhantomERC20} from "./IPhantomERC20.sol";

/**
 * @title IsPHM
 * @author PhantomDao Team
 * @notice The Interface for IsPHM
 */
interface IsPHM is IPhantomERC20 {

    event Phantom_Rebase(uint256 epochNumber, uint256 rewardYield, uint256 scalingFactor);
    event Phantom_RewardRateUpdate(uint256 oldRewardRate, uint256 newRewardRate);

    function doRebase(uint256 epochNumber) external;
    function updateCompoundingPeriodsPeriodYear(uint256 numPeriods) external;
    function updateRewardRate(uint256 numRewardRate) external;
    function interestPerPeriod() external view returns(uint256);
    function periodsPerYear() external view returns(uint256);
    function secondsPerCompoundingPeriod() external view returns(uint256);
    function scalingFactor() external view returns(uint256);

} 