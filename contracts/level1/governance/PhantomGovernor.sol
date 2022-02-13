/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "@hifi-finance/prb-math/contracts/PRBMathUD60x18.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Governor, IGovernor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorProposalThreshold} from "@openzeppelin/contracts/governance/extensions/GovernorProposalThreshold.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/* Internal Imports */
import {PhantomStorageMixin} from "../../mixins/PhantomStorageMixin.sol";

/* Internal Interface Imports */
import {IPhantomGovernor} from "../../../interfaces/level0/governance/IPhantomGovernor.sol";
import {IPhantomExecutor} from "../../../interfaces/level0/governance/IPhantomExecutor.sol";
import {IPhantomTreasury} from "../../../interfaces/core/IPhantomTreasury.sol";

/**
 * @title PhantomGovernor
 * @author PhantomDao Team
 * @notice The Governor of the PhantomNetwork
 */
contract PhantomGovernor is
    Governor,
    GovernorCountingSimple,
    GovernorProposalThreshold,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    PhantomStorageMixin
{

    mapping(uint256 => address) private _proposalOwners;

    constructor(
        address storageFactoryAddress,
        ERC20Votes _token,
        TimelockController _timelock,
        uint256 _quorumPercentage,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _proposalThreshold
    )
        Governor("Phantom Governor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumPercentage)
        GovernorTimelockControl(_timelock)
        PhantomStorageMixin(storageFactoryAddress)
    {
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.governor.votingDelay)), _votingDelay);
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.governor.votingPeriod)), _votingPeriod);
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.governor.quorumPercentage)), _quorumPercentage);
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.governor.proposalThreshold)), _proposalThreshold);
    }

    function votingDelay() public view override returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.governor.votingDelay))); // 1 = 1 block
    }

    function votingPeriod() public view override returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.governor.votingPeriod))); // 45818 = 1 week
    }

    function quorumNumerator() public view override returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.governor.quorumPercentage)));
    }

    function updateQuorumNumerator(uint256 newQuorumNumerator) external override onlyGovernance {
        super._updateQuorumNumerator(newQuorumNumerator);
        PhantomStorage().setUint(keccak256(abi.encodePacked(phantom.governor.quorumPercentage)), newQuorumNumerator);
    }

    function proposalThreshold() public view override returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked(phantom.governor.proposalThreshold)));
    }

    // The following functions are overrides required by Solidity.

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotes)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(GovernorProposalThreshold, Governor, IGovernor) returns (uint256) {
        uint256 proposalId = super.propose(targets, values, calldatas, description);
        _proposalOwners[proposalId] = msg.sender;
        return proposalId;
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
        delete _proposalOwners[proposalId];
    }

    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        require(
            _proposalOwners[proposalId] == msg.sender || getVotes(_proposalOwners[proposalId], block.number - 1) < proposalThreshold(),
            "PhantomGovernor: only proposal owner can cancel"
        );

        uint256 result = _cancel(
            targets,
            values,
            calldatas,
            descriptionHash
        );

        delete _proposalOwners[proposalId];

        return result;
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
