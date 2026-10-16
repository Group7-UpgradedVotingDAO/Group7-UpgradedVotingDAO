// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VotingDAO.sol";

contract VotingDAOTest is Test {
    VotingDAO dao;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        dao = new VotingDAO();
    }

    function testMemberCanJoinDAO() public {
        vm.prank(alice);
        dao.joinDAO();

        (bool isMember, uint256 votingPower) = dao.members(alice);
        assertTrue(isMember);
        assertEq(votingPower, 1);
    }

    function testCannotJoinTwice() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        vm.expectRevert(bytes("Already a member"));
        dao.joinDAO();
    }

    function testMemberCanCreateProposal() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        assertEq(dao.proposalCount(), 1);
    }

    function testNonMemberCannotCreateProposal() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Not a DAO member"));
        dao.createProposal("Upgrade the DAO", 1 days);
    }

    function testMemberCanVoteYes() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        vm.prank(alice);
        dao.vote(1, true);

        (, , uint256 yesVotes, , , ) = dao.proposals(1);
        assertEq(yesVotes, 1);
    }

    function testMemberCanVoteNo() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        vm.prank(alice);
        dao.vote(1, false);

        (, , , uint256 noVotes, , ) = dao.proposals(1);
        assertEq(noVotes, 1);
    }

    function testCannotVoteTwice() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        vm.prank(alice);
        dao.vote(1, true);

        vm.prank(alice);
        vm.expectRevert(bytes("Already voted"));
        dao.vote(1, false);
    }

    function testCannotVoteAfterDeadline() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        vm.warp(block.timestamp + 1 days);

        vm.prank(alice);
        vm.expectRevert(bytes("Voting has ended"));
        dao.vote(1, true);
    }

    function testProposalPassesWhenQuorumReached() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(bob);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        vm.prank(alice);
        dao.vote(1, true);

        vm.prank(bob);
        dao.vote(1, true);

        vm.warp(block.timestamp + 1 days);

        (bool quorumReached, bool passed) = dao.getProposalResult(1);

        assertTrue(quorumReached);
        assertTrue(passed);
    }

    function testProposalFailsWithoutQuorum() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        vm.prank(alice);
        dao.vote(1, true);

        vm.warp(block.timestamp + 1 days);

        (bool quorumReached, bool passed) = dao.getProposalResult(1);

        assertFalse(quorumReached);
        assertFalse(passed);
    }

    function testExecuteProposalAfterPassing() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(bob);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        vm.prank(alice);
        dao.vote(1, true);

        vm.prank(bob);
        dao.vote(1, true);

        vm.warp(block.timestamp + 1 days);

        dao.executeProposal(1);

        (, , , , , bool executed) = dao.proposals(1);
        assertTrue(executed);
    }

    function testCannotExecuteProposalWithoutQuorum() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        vm.prank(alice);
        dao.vote(1, true);

        vm.warp(block.timestamp + 1 days);

        vm.expectRevert(bytes("Quorum not reached"));
        dao.executeProposal(1);
    }
}