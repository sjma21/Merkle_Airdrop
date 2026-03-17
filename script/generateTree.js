const { MerkleTree } = require("merkletreejs")
const keccak256 = require("keccak256")
const { ethers } = require("ethers")
const fs = require("fs")

const data = JSON.parse(
  fs.readFileSync("./data/airdrop.json")
)

const leaves = data.map(x =>
  ethers.solidityPackedKeccak256(
    ["address","uint256"],
    [x.address,x.amount]
  )
)

const tree = new MerkleTree(leaves, keccak256, {
  sortPairs: true
})

const root = tree.getHexRoot()

console.log("MERKLE ROOT:", root)

data.forEach((x,i)=>{
 const proof = tree.getHexProof(leaves[i])

 console.log("\nAddress:",x.address)
 console.log("Amount:",x.amount)
 console.log("Proof:",proof)
})


// 0x02d6d34f044b4b5c4bf206cf09aea0f46d6fa5ffee5ba905e3693e4fd6907ed3