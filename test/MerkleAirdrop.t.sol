// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {MockToken} from "../src/MockToken.sol";

contract MerkleAirdropTest is Test {

    MockToken public token;
    MerkleAirdrop public airdrop;

    bytes32 constant MERKLE_ROOT =
        0xbca2149fc97cda4b84f4b3f59eefca0d8239f2c3eba310a50e8ad7f7446a01af;

    // Airdrop recipients from data/airdrop.json
    address constant USER1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant USER2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant USER3 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    uint256 constant AMOUNT1 = 100 ether;
    uint256 constant AMOUNT2 = 200 ether;
    uint256 constant AMOUNT3 = 300 ether;

    // Pre-computed proofs from generateTree.js
    bytes32[] proof1;
    bytes32[] proof2;
    bytes32[] proof3;

    function setUp() public {
        token = new MockToken();
        airdrop = new MerkleAirdrop(MERKLE_ROOT, address(token));

        // Fund the airdrop contract with enough tokens
        token.transfer(address(airdrop), 1000 ether);

        // Proof for USER1 (100 ether)
        proof1 = new bytes32[](2);
        proof1[0] = 0x5dd2f5b00ec4f69554cd962debf239faf3026e0fd82a6da3db64c1623b3fbe39;
        proof1[1] = 0x152f9b12cc5eb89244ccee5333d120f5e6ecdc1c649a6b4d064a46d8adcaf4f5;

        // Proof for USER2 (200 ether)
        proof2 = new bytes32[](2);
        proof2[0] = 0x271e61abd8219c77862fda17c0c094302fa9884962394db34da950745db9fbbb;
        proof2[1] = 0x152f9b12cc5eb89244ccee5333d120f5e6ecdc1c649a6b4d064a46d8adcaf4f5;

        // Proof for USER3 (300 ether)
        proof3 = new bytes32[](1);
        proof3[0] = 0xe784947b020062fe9fdcce6bcd9d7dffe996473eba8d7a6f4263a7803f2631ab;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Deployment / state checks
    // ──────────────────────────────────────────────────────────────────────────

    function test_MerkleRootIsSetCorrectly() public view {
        assertEq(airdrop.merkleRoot(), MERKLE_ROOT);
    }

    function test_TokenAddressIsSetCorrectly() public view {
        assertEq(address(airdrop.token()), address(token));
    }

    function test_AirdropContractReceivesTokens() public view {
        assertEq(token.balanceOf(address(airdrop)), 1000 ether);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Successful claims
    // ──────────────────────────────────────────────────────────────────────────

    function test_User1CanClaim() public {
        uint256 balanceBefore = token.balanceOf(USER1);
        airdrop.claim(USER1, AMOUNT1, proof1);
        assertEq(token.balanceOf(USER1), balanceBefore + AMOUNT1);
    }

    function test_User2CanClaim() public {
        uint256 balanceBefore = token.balanceOf(USER2);
        airdrop.claim(USER2, AMOUNT2, proof2);
        assertEq(token.balanceOf(USER2), balanceBefore + AMOUNT2);
    }

    function test_User3CanClaim() public {
        uint256 balanceBefore = token.balanceOf(USER3);
        airdrop.claim(USER3, AMOUNT3, proof3);
        assertEq(token.balanceOf(USER3), balanceBefore + AMOUNT3);
    }

    function test_AllUsersCanClaimSequentially() public {
        airdrop.claim(USER1, AMOUNT1, proof1);
        airdrop.claim(USER2, AMOUNT2, proof2);
        airdrop.claim(USER3, AMOUNT3, proof3);

        assertEq(token.balanceOf(USER1), AMOUNT1);
        assertEq(token.balanceOf(USER2), AMOUNT2);
        assertEq(token.balanceOf(USER3), AMOUNT3);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Claimed mapping state
    // ──────────────────────────────────────────────────────────────────────────

    function test_ClaimedMappingIsFalseBeforeClaim() public view {
        assertFalse(airdrop.claimed(USER1));
        assertFalse(airdrop.claimed(USER2));
        assertFalse(airdrop.claimed(USER3));
    }

    function test_ClaimedMappingIsTrueAfterClaim() public {
        airdrop.claim(USER1, AMOUNT1, proof1);
        assertTrue(airdrop.claimed(USER1));
    }

    function test_ClaimedMappingOnlyUpdatesClaimedUser() public {
        airdrop.claim(USER1, AMOUNT1, proof1);
        assertTrue(airdrop.claimed(USER1));
        assertFalse(airdrop.claimed(USER2));
        assertFalse(airdrop.claimed(USER3));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Contract balance after claims
    // ──────────────────────────────────────────────────────────────────────────

    function test_ContractBalanceDecreasesAfterClaim() public {
        uint256 contractBalanceBefore = token.balanceOf(address(airdrop));
        airdrop.claim(USER1, AMOUNT1, proof1);
        assertEq(token.balanceOf(address(airdrop)), contractBalanceBefore - AMOUNT1);
    }

    function test_ContractBalanceAfterAllClaims() public {
        airdrop.claim(USER1, AMOUNT1, proof1);
        airdrop.claim(USER2, AMOUNT2, proof2);
        airdrop.claim(USER3, AMOUNT3, proof3);
        // 1000 - 100 - 200 - 300 = 400 ether remaining
        assertEq(token.balanceOf(address(airdrop)), 400 ether);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Revert: double-claim
    // ──────────────────────────────────────────────────────────────────────────

    function test_RevertIfAlreadyClaimed() public {
        airdrop.claim(USER1, AMOUNT1, proof1);
        vm.expectRevert("Already claimed");
        airdrop.claim(USER1, AMOUNT1, proof1);
    }

    function test_RevertIfUser2TriesToClaimTwice() public {
        airdrop.claim(USER2, AMOUNT2, proof2);
        vm.expectRevert("Already claimed");
        airdrop.claim(USER2, AMOUNT2, proof2);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Revert: invalid proof
    // ──────────────────────────────────────────────────────────────────────────

    function test_RevertIfProofIsEmpty() public {
        bytes32[] memory emptyProof = new bytes32[](0);
        vm.expectRevert("Invalid proof");
        airdrop.claim(USER1, AMOUNT1, emptyProof);
    }

    function test_RevertIfWrongProofUsed() public {
        // USER1 trying to claim with USER2's proof
        vm.expectRevert("Invalid proof");
        airdrop.claim(USER1, AMOUNT1, proof2);
    }

    function test_RevertIfWrongAmountWithValidProof() public {
        // Correct address, correct proof, but wrong amount
        vm.expectRevert("Invalid proof");
        airdrop.claim(USER1, AMOUNT2, proof1);
    }

    function test_RevertIfWrongAddressWithValidProof() public {
        // Wrong address but using USER1's proof
        address randomUser = address(0xDEAD);
        vm.expectRevert("Invalid proof");
        airdrop.claim(randomUser, AMOUNT1, proof1);
    }

    function test_RevertIfProofIsManipulated() public {
        // Flip one byte of a valid proof element
        proof1[0] = bytes32(uint256(proof1[0]) ^ 1);
        vm.expectRevert("Invalid proof");
        airdrop.claim(USER1, AMOUNT1, proof1);
    }

    function test_RevertIfUnlistedAddressClaims() public {
        address attacker = address(0xBAD);
        bytes32[] memory fakeProof = new bytes32[](1);
        fakeProof[0] = keccak256(abi.encodePacked(attacker, uint256(100 ether)));
        vm.expectRevert("Invalid proof");
        airdrop.claim(attacker, 100 ether, fakeProof);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Claim caller does not need to be the recipient
    // ──────────────────────────────────────────────────────────────────────────

    function test_AnyoneCanTriggerClaimOnBehalfOfRecipient() public {
        address relayer = address(0xCAFE);
        vm.prank(relayer);
        airdrop.claim(USER1, AMOUNT1, proof1);
        assertEq(token.balanceOf(USER1), AMOUNT1);
    }
}
