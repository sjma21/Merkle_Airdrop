// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MerkleAirdrop.sol";
import "../src/MockToken.sol";

contract Deploy is Script {

 function run() external {

  vm.startBroadcast();

  MockToken token=new MockToken();

  bytes32 root = 0xbca2149fc97cda4b84f4b3f59eefca0d8239f2c3eba310a50e8ad7f7446a01af;

  MerkleAirdrop airdrop=
   new MerkleAirdrop(root,address(token));

  token.transfer(address(airdrop),1000 ether);

  vm.stopBroadcast();
 }
}

