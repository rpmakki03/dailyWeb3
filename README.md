# 🌐 Full Web3 System – ERC20 + NFT + Staking + DAO + Treasury

This project is a **single Solidity smart contract system (\~700 lines)** that combines:

✅ **ERC20 Token (MyToken)**
✅ **ERC721 NFT (MyNFT)**
✅ **Staking System (Stake MyToken to earn rewards)**
✅ **DAO Governance (Proposals + Voting)**
✅ **Treasury (Holds ETH & Tokens)**
✅ **MainContract – deploys and links everything**

---

## 📂 Features

### 🔹 ERC20 Token – MyToken

* Deploys a custom token `MyToken` (MTK) with **initial supply = 1,000,000 MTK**
* Supports `transfer`, `approve`, `transferFrom`, `mint`, `burn`

### 🔹 ERC721 NFT – MyNFT

* Simple NFT contract that lets the **owner mint NFTs**
* Each NFT has a custom metadata URI

### 🔹 Staking – Stake MTK to earn rewards

* Users can **stake MyToken**
* Earn rewards at `0.01 MTK / second`
* Withdraw staked tokens + rewards anytime

### 🔹 DAO Governance – Voting with MTK

* Token holders **create proposals**
* Voting power = MTK balance
* After deadline, owner can **execute proposals**

### 🔹 Treasury – Fund Management

* Holds ETH and MTK
* Owner can withdraw ETH/MTK

### 🔹 MainContract

* Deploys **all contracts automatically**
* Provides helper functions for NFT minting, funding treasury, etc.

---

## ⚡ Deployment

### 1️⃣ Open Remix

* Go to [Remix IDE](https://remix.ethereum.org/)
* Create a new file `FullSystem.sol`
* Paste the entire code

### 2️⃣ Compile

* Compiler version: **0.8.18 or above**
* Enable **Auto Compile**

### 3️⃣ Deploy

* Deploy **MainContract**
  ✅ It will **automatically create all subcontracts (ERC20, NFT, Staking, DAO, Treasury)**.

---

## 🔑 Functions Overview

### **MainContract**

| Function                       | Description              |
| ------------------------------ | ------------------------ |
| `token()`                      | Returns MyToken address  |
| `nft()`                        | Returns MyNFT address    |
| `staking()`                    | Returns Staking address  |
| `dao()`                        | Returns DAO address      |
| `treasury()`                   | Returns Treasury address |
| `mintNFT(address, string)`     | Mint NFT to a user       |
| `sendTokens(address, uint256)` | Send MTK tokens          |
| `fundTreasury()`               | Send ETH to treasury     |

---

### **MyToken (ERC20)**

* `transfer(to, amount)` → Transfer MTK
* `approve(spender, amount)` → Approve MTK spending
* `transferFrom(from, to, amount)` → Transfer on behalf
* `mint(to, amount)` → Owner can mint tokens
* `burn(amount)` → Burn tokens

---

### **MyNFT (ERC721)**

* `mint(to, uri)` → Owner mints NFT
* `transfer(to, tokenId)` → Transfer NFT

---

### **Staking**

* `stake(amount)` → Stake MTK tokens
* `unstake(amount)` → Withdraw tokens + rewards
* `calculateReward(user)` → View pending rewards

---

### **DAO**

* `createProposal(description)` → Create a proposal
* `vote(proposalId, support)` → Vote For/Against
* `executeProposal(proposalId)` → Owner executes proposal

---

### **Treasury**

* Send ETH directly to the contract
* `withdrawETH(to, amount)` → Owner withdraws ETH
* `withdrawTokens(to, amount)` → Owner withdraws MTK

---

## 🚀 Example Workflow

### ✅ **Initial Setup**

1. Deploy `MainContract`
2. Copy contract addresses for Token, NFT, Staking, DAO, Treasury

### ✅ **Token Actions**

* Transfer tokens to users using `sendTokens()`

### ✅ **NFT Minting**

* `mintNFT(user, "ipfs://metadata.json")`

### ✅ **Staking**

* Approve token spending
* Stake MTK using `stake(amount)`
* Later, call `unstake(amount)` to get rewards

### ✅ **DAO**

* Create proposal → `createProposal("Fund project A")`
* Token holders vote → `vote(proposalId, true/false)`
* After deadline → `executeProposal(proposalId)`

---

## 🛠 Development

### Install Dependencies (Hardhat)

```bash
mkdir web3-system
cd web3-system
npm init -y
npm install --save-dev hardhat
npx hardhat
```

### Compile & Deploy

```bash
npx hardhat compile
npx hardhat run scripts/deploy.js --network <network>
```

---

## 🔒 Security

✔ Reentrancy protection
✔ Owner-only minting and withdrawals
✔ Token-based DAO voting

---


