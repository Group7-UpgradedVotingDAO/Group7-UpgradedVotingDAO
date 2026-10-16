// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VotingDAO {
    struct Proposal {
        uint256 id;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
        bool executed;
    }

    uint256 public proposalCount;
uint256 public constant MINIMUM_QUORUM = 2;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    struct Member {
        bool isMember;
        uint256 votingPower;
    }

    mapping(address => Member) public members;
    uint256 public memberCount;
    event MemberJoined(address indexed member, uint256 votingPower);

    function joinDAO() external {
        require(!members[msg.sender].isMember, "Already a member");

        members[msg.sender] = Member({isMember: true, votingPower: 1});
        memberCount++;
        emit MemberJoined(msg.sender, 1);
    }
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        uint256 deadline
    );
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 votingPower
    );
    function createProposal(
        string memory _description,
        uint256 _duration
    ) external {
        require(members[msg.sender].isMember, "Not a DAO member");
        require(_duration > 0, "Duration must be greater than zero");

        proposalCount++;

        uint256 deadline = block.timestamp + _duration;

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: _description,
            yesVotes: 0,
            noVotes: 0,
            deadline: deadline,
            executed: false
        });

        emit ProposalCreated(proposalCount, msg.sender, _description, deadline);
    }
    function vote(uint256 _proposalId, bool _support) external {
        require(members[msg.sender].isMember, "Not a DAO member");
        require(
            _proposalId > 0 && _proposalId <= proposalCount,
            "Invalid proposal"
        );
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp < proposal.deadline, "Voting has ended");

        uint256 votingPower = members[msg.sender].votingPower;

        if (_support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        hasVoted[_proposalId][msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }
}
function getProposalResult(
        uint256 _proposalId
    ) external view returns (bool quorumReached, bool passed) {
        require(
            _proposalId > 0 && _proposalId <= proposalCount,
            "Invalid proposal"
        );

        Proposal storage proposal = proposals[_proposalId];

        require(
            block.timestamp >= proposal.deadline,
            "Voting is still active"
        );

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;

        quorumReached = totalVotes >= MINIMUM_QUORUM;
        passed = quorumReached && proposal.yesVotes > proposal.noVotes;
    }