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

        (bool isMember, uint256 power) = dao.members(alice);

        assertTrue(isMember);
        assertEq(power, 1);
        assertEq(dao.memberCount(), 1);
    }

    function testCannotJoinTwice() public {
        vm.startPrank(alice);
        dao.joinDAO();

        vm.expectRevert(bytes("Already a member"));
        dao.joinDAO();
        vm.stopPrank();
    }

    function testMemberCanCreateProposal() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        assertEq(dao.proposalCount(), 1);

        (uint256 id, , , , , ) = dao.proposals(1);
        assertEq(id, 1);
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
        assertTrue(dao.hasVoted(1, alice));
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

        vm.startPrank(alice);
        dao.vote(1, true);

        vm.expectRevert(bytes("Already voted"));
        dao.vote(1, false);
        vm.stopPrank();
    }

    function testNonMemberCannotVote() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        dao.createProposal("Upgrade the DAO", 1 days);

        vm.prank(bob);
        vm.expectRevert(bytes("Not a DAO member"));
        dao.vote(1, true);
    }

    function testCannotVoteOnInvalidProposal() public {
        vm.prank(alice);
        dao.joinDAO();

        vm.prank(alice);
        vm.expectRevert(bytes("Invalid proposal"));
        dao.vote(1, true);
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
}