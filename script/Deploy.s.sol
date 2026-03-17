// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MerkleAirdrop.sol";
import "../src/MockToken.sol";

contract Deploy is Script {

 function run() external {

  vm.startBroadcast();

  MockToken token=new MockToken();

  bytes32 root = 0xeb516dbd7629ce3fe7bb23bb314e62981e9c4ca6565f57706ab5b65c38b66cd4;

  MerkleAirdrop airdrop=
   new MerkleAirdrop(root,address(token));

  token.transfer(address(airdrop),1000 ether);

  vm.stopBroadcast();
 }
}

