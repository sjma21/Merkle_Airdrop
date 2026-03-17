# Merkle Airdrop

A gas-efficient token airdrop system built with Solidity and Foundry. Eligible recipients are stored off-chain as a Merkle tree; only the root is stored on-chain, and each user submits a Merkle proof to claim their tokens.

---

## How It Works

1. A list of eligible addresses and amounts is defined in `data/airdrop.json`.
2. A Merkle tree is generated off-chain from that data using the `script/generateTree.js` script.
3. The Merkle root is hardcoded into the deploy script and stored immutably in the `MerkleAirdrop` contract.
4. Users claim their tokens by calling `claim()` with their address, amount, and Merkle proof.
5. A `claimed` mapping prevents double-claiming.

---

## Project Structure

```
merkle-airdrop/
├── src/
│   ├── MerkleAirdrop.sol      # Core airdrop contract (Merkle proof verification + claim logic)
│   └── MockToken.sol          # ERC20 mock token (mints 1,000,000 MTK to deployer)
├── script/
│   ├── Deploy.s.sol           # Foundry deploy script (deploys MockToken + MerkleAirdrop)
│   └── generateTree.js        # Node.js script to build the Merkle tree and output proofs
├── data/
│   └── airdrop.json           # List of eligible addresses and claimable amounts (in wei)
├── test/
│   └── Counter.t.sol          # Placeholder test file
├── lib/
│   ├── forge-std/             # Foundry standard library
│   └── openzeppelin-contracts/ # OpenZeppelin contracts
├── remappings.txt             # Solidity import remappings
├── foundry.toml               # Foundry configuration
└── README.md
```

---

## Contracts

### `MerkleAirdrop.sol`

| Item | Details |
|---|---|
| `merkleRoot` | Immutable Merkle root set at deployment |
| `token` | ERC20 token to distribute |
| `claimed` | Mapping to track claimed addresses |
| `claim(address, uint256, bytes32[])` | Verifies proof and transfers tokens to the claimant |

Leaves are encoded as `keccak256(abi.encodePacked(account, amount))`.

### `MockToken.sol`

A simple ERC20 token (`MockToken` / `MTK`) that mints **1,000,000 MTK** to the deployer on construction. Used for local testing and deployment.

---

## Airdrop Data (`data/airdrop.json`)

Eligible recipients and their claimable amounts (in wei):

| Address | Amount |
|---|---|
| `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | 100 MTK |
| `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | 200 MTK |
| `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | 300 MTK |

---

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) — for building and deploying contracts
- [Node.js](https://nodejs.org/) — for running the Merkle tree generation script

---

## Setup

### 1. Install Foundry dependencies

```shell
forge install
```

### 2. Install Node.js dependencies

```shell
npm install merkletreejs keccak256 ethers
```

---

## Generating the Merkle Tree

Run the script to generate the Merkle root and proofs for each address:

```shell
node script/generateTree.js
```

This reads `data/airdrop.json` and outputs:
- The **Merkle root** (paste this into `Deploy.s.sol`)
- The **proof** for each eligible address

---

## Build & Test

```shell
# Compile contracts
forge build

# Run tests
forge test

# Format code
forge fmt

# Gas snapshots
forge snapshot
```

---

## Deployment

### Local (Anvil)

Start a local node:

```shell
anvil
```

Deploy using the deploy script:

```shell
forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <your_private_key> \
  --broadcast
```

### Testnet / Mainnet

```shell
forge script script/Deploy.s.sol:Deploy \
  --rpc-url <your_rpc_url> \
  --private-key <your_private_key> \
  --broadcast \
  --verify
```

> **Note:** Update the `root` value in `Deploy.s.sol` with the Merkle root output from `generateTree.js` before deploying.

---

## Claiming Tokens

After deployment, a user can claim their tokens by calling `claim` with their address, amount, and proof (obtained from `generateTree.js`):

```shell
cast send <AIRDROP_CONTRACT_ADDRESS> \
  "claim(address,uint256,bytes32[])" \
  <your_address> <amount_in_wei> "[<proof_bytes32>, ...]" \
  --rpc-url <your_rpc_url> \
  --private-key <your_private_key>
```

---

## Dependencies

| Library | Purpose |
|---|---|
| [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) | `MerkleProof`, `IERC20`, `ERC20` |
| [forge-std](https://github.com/foundry-rs/forge-std) | Foundry testing & scripting utilities |
| [merkletreejs](https://github.com/miguelmota/merkletreejs) | Off-chain Merkle tree construction |
| [keccak256](https://github.com/nicowillis/keccak256) | Hashing for Merkle leaves |
| [ethers.js](https://docs.ethers.org/) | ABI encoding for leaf generation |
