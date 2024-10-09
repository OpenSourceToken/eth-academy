// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct Proposal {
        bytes32 name;
        uint voteCount;
    }

    address public chairperson;
    uint public startTime; // 投票开始时间
    uint public endTime;   // 投票结束时间

    mapping(address => Voter) public voters;

    Proposal[] public proposals;
    
    constructor(bytes32[] memory proposalNames, uint _startTime, uint _endTime) {
        require(_startTime < _endTime, "Start time must be before end time");
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        startTime = _startTime;
        endTime = _endTime;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    function giveRightToVote(address voter) external {
        require(
            msg.sender == chairperson,
            "only chairperson can give right to vote"
        );
        require(!voters[voter].voted, "voter already voted");
        require(voters[voter].weight == 0, "voter already has weight");
        voters[voter].weight = 1;
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no rtght to vote");
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation isdisallowed.");
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }
        Voter storage delegate_ = voters[to];
        require(delegate_.weight >= 1);
        sender.voted = true;
        sender.delegate = to;
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposal) external {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Voting is not within the allowed time frame");

        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no rtght to vote");    
        require(!sender.voted, "You already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    function winnerName() public view returns (bytes32 winnerName_) {
        uint winningProposal_ = winningProposal();
        winnerName_ = proposals[winningProposal_].name;
    }
}
