/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {ERC20} from "./SolmateERC20.sol";
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IgPHM} from "../../../interfaces/core/erc20/IgPHM.sol";

/**
 * @title gPHM
 * @author PhantomDao Team
 * @notice The Governance Phantom Token
 */
contract gPHM is IgPHM, ERC20, PhantomStorageMixin {
    using PRBMathUD60x18 for uint256;

    bool transfersFrozen = true;

    constructor(address storageFactoryAddress)
        ERC20("Governance Phantom", "gPHM", 18)
        PhantomStorageMixin(storageFactoryAddress)
    {
        return;
    }

    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => bool) public isApprovedDelegatee;
    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    //=================================================================================================================
    // External Functions
    //=================================================================================================================

    /**
     * @dev turn on transfers for this token. This is a one-time action.
     */
    function enableTransfers() external onlyRegisteredContracts {
        transfersFrozen = false;
    }

    /**
     * @dev add an approved delegate.
     */
    function addApprovedDelegatee(address delegatee) external onlyRegisteredContracts {
        _addApprovedDelegatee(delegatee);
    }

    //=================================================================================================================
    // Public Functions
    //=================================================================================================================

    function delegates(address delegator) public view virtual returns (address delegatee) {
        address current = _delegates[delegator];

        delegatee = current == address(0) ? delegator : current;
    }

    function delegate(address delegatee) public virtual {
        _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "ZERO_ADDRESS");

        // this is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
        unchecked {
            require(nonce == nonces[signatory]++, "INVALID_NONCE");
        }

        require(block.timestamp <= expiry, "SIGNATURE_EXPIRED");

        _delegate(signatory, delegatee);
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */    
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256 votes) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @notice calculate conversion between an amount of gPHM to (s)PHM
     * @param amount uint amount of gPHM
     * @return uint equivalent amount of (s)PHM
     */
    function balanceToPHM(uint256 amount) public view returns (uint256) {
        return amount.mul(sPHM().scalingFactor());
    }

    /**
     * @notice calculate conversion between an amount of (s)PHM to gPHM
     * @param amount uint amount of (s)PHM
     * @return uint equivalent amount of gPHM
     */
    function balanceFromPHM(uint256 amount) public view returns (uint256) {
        return amount.div(sPHM().scalingFactor());
    }

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    //=================================================================================================================
    // ERC20 Overrides
    //=================================================================================================================

    /**
     * @dev prevent more than 4.76% ownership unless you are the treasury
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        if (transfersFrozen == true) {
            require(from == address(0) || to == address(0), "gPHM is not transferable");
        } else if (to != address(PhantomVault()) && to != address(0)) {
            require(
                PHM().balanceAllDenoms(to) < PHM().maxBalancePerWallet(),
                "gPHM transfer blocked due to owning over 4.76% of supply"
            );
        }

        super._afterTokenTransfer(from, to, amount);

        _moveDelegates(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= type(uint224).max, "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    function mint(address to, uint256 amount) external onlyRegisteredContracts {
        _mint(to, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    function burn(address account, uint256 amount) external onlyRegisteredContracts {
        _burn(account, amount);
    }

    //=================================================================================================================
    // Internal Functions
    //=================================================================================================================

    function _addApprovedDelegatee(address delegatee) internal {
        isApprovedDelegatee[delegatee] = true;
    }

    function _delegate(address delegator, address delegatee) internal virtual {
        if (delegator != delegatee && delegatee != address(0)) {
            require(isApprovedDelegatee[delegatee] == true, "Can't deletagte to delegatee");
        }
        address currentDelegate = _delegates[delegator];

        _delegates[delegator] = delegatee;

        _moveDelegates(currentDelegate, delegatee, _balanceOf[delegator]);

        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }

    function _moveDelegates(
        address src,
        address dst,
        uint256 amount
    ) internal virtual {
        if (src!= dst&& amount > 0)
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
    }

    //=================================================================================================================
    // Private Functions
    //=================================================================================================================

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}
