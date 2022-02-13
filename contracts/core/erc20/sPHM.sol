/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {ERC20} from "./SolmateERC20.sol";
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";

/* Interface Imports */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IsPHM} from "../../../interfaces/core/erc20/IsPHM.sol";

/**
 * @title sPHM
 * @author PhantomDao Team
 * @notice The Staked Phantom Token
 */
contract sPHM is PhantomStorageMixin, IsPHM, ERC20 {
    using PRBMathUD60x18 for uint256;

    uint256 public _totalSupplyInternal; // UD60x18
    uint256 public _scalingFactorBase; // UD60x18
    uint256 public _timestampOfLastRebase;
    uint256 public _compoundingPeriodsPerYear;
    uint256 public _newCompoundingPeriodsPerYear;
    uint256 public _apy;
    uint256 public _apr;
    uint256 public _rewardRate;

    mapping(address => uint256) public internalBalances;

    constructor(address storageAddress, uint256 compoindingPeriodsPerYear)
        ERC20("Staked Phantom", "sPHM", 18)
        PhantomStorageMixin(storageAddress)
    {
        _timestampOfLastRebase = block.timestamp;
        _scalingFactorBase = 1e18;
        _compoundingPeriodsPerYear = compoindingPeriodsPerYear;
    }

    //=================================================================================================================
    // Public Functions
    //=================================================================================================================

    uint256 internal constant SECONDS_PER_YEAR = 31_536_000;

    function scalingFactor() public view returns (uint256) {
        return _scalingFactorBase;
    }

    /**
     * @dev Get the current rewardYeild. This depends on supply of PHM, sPHM, gPHM and fPHM.
     */
    function rewardYield() public view returns (uint256) {
        uint256 supply = totalSupply() +
            gPHM().totalSupply().mul(scalingFactor()) +
            fPHM().totalSupply().mul(scalingFactor());
        if (supply == 0) return 0;

        return PHM().totalSupply().mul(rewardRate()).div(supply);
    }

    function rewardRate() public view returns (uint256) {
        return _rewardRate;
    }

    function apy() public view returns (uint256) {
        return _apy;
    }

    function apr() public view returns (uint256) {
        return _apr;
    }

    function relativeCurrentTimeStamp() public view returns (uint256) {
        return block.timestamp - _timestampOfLastRebase;
    }

    function interestPerPeriod() public view returns (uint256) {
        return apr().div(periodsPerYear().fromUint());
    }

    function periodsPerYear() public view returns (uint256) {
        return _compoundingPeriodsPerYear == 0 ? 1 : _compoundingPeriodsPerYear;
    }

    function secondsPerCompoundingPeriod() public view returns (uint256) {
        return SECONDS_PER_YEAR / periodsPerYear();
    }

    function internalValueOf(uint256 amount) public view returns (uint256) {
        return amount.div(scalingFactor());
    }

    function externalValueOf(uint256 internalAmount) public view returns (uint256) {
        return internalAmount.mul(scalingFactor());
    }

    function internalBalanceOf(address user) public view returns (uint256) {
        return internalBalances[user];
    }

    function balanceOf(address user) public view override(ERC20, IERC20) returns (uint256) {
        return (internalBalanceOf(user).mul(scalingFactor()));
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    /**
     * @dev Perform a rebase. In reality, this calculates the new APY and updates the _scalingFactorBase.
     * This needs to be called by the contract responsible for triggering rebases.
     */
    function doRebase(uint256 epochNumber) external onlyRegisteredContracts {
        uint256 rewardYield_ = rewardYield();

        require(
            (ONE_18D + rewardYield_).powu((periodsPerYear() + 63) / 64) <= uint256(1)<<(2+64),
            "sPHM: rewardRate too high and is causing overflow"
        );

        _apy = (ONE_18D + rewardYield_).powu(periodsPerYear());
        _apr = rewardYield_.mul(periodsPerYear().fromUint());

        _scalingFactorBase = _calculateScalingFactorBase();
        _timestampOfLastRebase = block.timestamp;

        emit Phantom_Rebase(epochNumber, rewardYield_, _scalingFactorBase);

        if (_newCompoundingPeriodsPerYear > 0) {
            _compoundingPeriodsPerYear = _newCompoundingPeriodsPerYear;
            _newCompoundingPeriodsPerYear = 0;
        }
    }

    /**
     * @dev Update the rewardRate
     * @param newRewardRate uint256 the new reward rate. 1e18 == 100% 1e17 == 10%,
     * 1e16 == 1%, 1e15 == 0.5%, 0 = 0%
     */
    function updateRewardRate(uint256 newRewardRate) external onlyRegisteredContracts {
        emit Phantom_RewardRateUpdate(_rewardRate, newRewardRate);
        _rewardRate = newRewardRate;
    }

    /**
     * @dev Update the number of compounding periods per year.
     * @param newPeriods uint256 a number greater than 0
     */
    function updateCompoundingPeriodsPeriodYear(uint256 newPeriods) external onlyRegisteredContracts {
        require(newPeriods > 0, "Compunding periods must be greater than 0");
        _newCompoundingPeriodsPerYear = newPeriods;
    }

    function mint(address inUser, uint256 inAmount) external override onlyRegisteredContracts {
        _mint(inUser, inAmount);
    }

    function burn(address fromUser, uint256 burnAmount) external override onlyRegisteredContracts {
        _burn(fromUser, burnAmount);
    }

    function _calculateScalingFactorBase() internal returns (uint256) {
        return 
            _scalingFactorBase.mul(
                (1e18 + interestPerPeriod()).pow(
                    (relativeCurrentTimeStamp() / secondsPerCompoundingPeriod()).fromUint()
                ) // intentional integer division with loss of precision, so that balances only update once a period
            );
    }

    //=================================================================================================================
    // ERC20 Overrides
    //=================================================================================================================

    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return _totalSupplyInternal.mul(scalingFactor());
    }

    function transfer(address recipient, uint256 amount) public virtual override(ERC20, IERC20) returns (bool) {
        internalBalances[msg.sender] -= internalValueOf(amount);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            internalBalances[recipient] += internalValueOf(amount);
        }
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override(ERC20, IERC20) returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        internalBalances[from] -= internalValueOf(amount);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            internalBalances[to] += internalValueOf(amount);
        }

        emit Transfer(from, to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal virtual override {
        _totalSupplyInternal += internalValueOf(amount);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            internalBalances[to] += internalValueOf(amount);
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual override {
        internalBalances[from] -= internalValueOf(amount);

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupplyInternal -= internalValueOf(amount);
        }

        emit Transfer(from, address(0), amount);
    }

    /**
     * @dev prevent more than 4.76% ownership unless you are the treasury
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        if (to != address(PhantomVault()) && to != address(0)) {
            require(
                PHM().balanceAllDenoms(to) < PHM().maxBalancePerWallet(),
                "sPHM transfer blocked due to owning over 4.76% of supply"
            );
        }
    }
}
