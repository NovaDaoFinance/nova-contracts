import brownie

def test_proposal(contracts, accounts, chain):
    vault = contracts["vault"]
    governor = contracts["governor"]
    gphm = contracts["gphm"]
    proposer = accounts[1]
    sheep = accounts[2]
    wolf = accounts[3]

    gphm.mint(vault.address, 100e18)
    gphm.mint(proposer.address, 4e18)
    gphm.mint(sheep.address, 4e18)

    proposal = governor.propose(
        ['0x0000000000000000000000000000000000000000',], 
        [0,], 
        ['',], 
        "This is a dummy proposal", 
        {"from": sheep}
    )
    assert governor.proposalVotes(proposal.return_value) == (0, 0, 0,)
    assert governor.state(proposal.return_value) == 1  # Active

    chain.sleep(10)
    chain.mine()

    assert governor.state(proposal.return_value) == 1  # Active
    governor.castVote(proposal.return_value, 1, {"from": sheep})  # For
    governor.castVote(proposal.return_value, 1, {"from": proposer})  # For
    with brownie.reverts('GovernorVotingSimple: vote already cast'):
        governor.castVote(proposal.return_value, 2, {"from": proposer})  # For
    governor.castVote(proposal.return_value, 0, {"from": wolf})  # Should have no affect
    assert governor.proposalVotes(proposal.return_value) == (0, 8e18, 0,)
    with brownie.reverts('GovernorVotingSimple: vote already cast'):
        governor.castVote(proposal.return_value, 0, {"from": sheep})  # Against
    assert governor.proposalVotes(proposal.return_value) == (0, 8e18, 0,)
    
    chain.sleep(governor.votingPeriod()*10)
    chain.mine()