// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MerkleAirdrop {

 bytes32 public immutable merkleRoot;
 IERC20 public token;

 mapping(address => bool) public claimed;

 constructor(bytes32 _root,address _token){
  merkleRoot=_root;
  token=IERC20(_token);
 }

 function claim(
  address account,
  uint256 amount,
  bytes32[] calldata proof
 ) external {

  require(!claimed[account],"Already claimed");

  bytes32 leaf=keccak256(
   abi.encodePacked(account,amount)
  );

  require(
   MerkleProof.verify(proof,merkleRoot,leaf),
   "Invalid proof"
  );

  claimed[account]=true;

  token.transfer(account,amount);
 }
}