# Decentralized Crypto Bank: Multi-User Native ETH Vault & Ledger

A secure, gas-optimized multi-user vault smart contract written in Solidity `0.8.36`. Implements native Ether deposits, withdrawals, internal ledger settlement, and strict Reentrancy protection via the **Checks-Effects-Interactions (CEI)** pattern.

---

## 📌 Architecture & Features

```text
       [ User Wallet ]
        │         ▲
 deposit│         │ withdraw / withdrawTo
 (ETH)  ▼         │ (.call)
┌─────────────────────────────────────────┐
│              CryptoBank                 │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  mapping(address => uint256)        │ │
│ │  userBalance (Internal Ledger)      │ │
│ └─────────────────────────────────────┘ │
│                     │                   │
│      transferInternal (0 ETH Moved)     │
│                     ▼                   │
│ ┌─────────────────────────────────────┐ │
│ │  Recipient Internal Balance Updated │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### 1. Checks-Effects-Interactions (CEI) & Native Withdrawals
- **Standard Withdrawal (`withdraw`):** Transfers native ETH back to `msg.sender`.
- **Delegated Withdrawal (`withdrawTo`):** Sends native ETH directly to a third-party recipient address.
- **Reentrancy Protection:** Decrements `userBalance[msg.sender]` in storage *before* executing the low-level `.call{value: amount}("")`.

### 2. Internal Ledger Settlement (`transferInternal`)
- **Zero ETH Overhead:** Allows users to transfer funds between accounts inside the bank without triggering native ETH transfers.
- **Gas Optimized:** Executes as an internal state re-allocation (`sender -= amount`, `recipient += amount`), enforcing individual `maxBalance` limits on the receiver.

### 3. Automated ETH Fallback Routing
- **`receive()` & `fallback()`:** Captures direct plain ETH transactions sent to the contract address and routes them automatically to `deposit()`, crediting the sender's account.

### 4. Gas-Optimized Error Handling
- Replaced classic `require(..., "string")` statements with top-level parameterized **Custom Errors** (`error Bank__...`), reducing bytecode size and gas costs on transaction reverts.

---

## 🛠️ File Structure

```text
├── contracts/
│   └── CryptoBank.sol
└── README.md
```

Custom Errors Reference
Custom Error	Parameter Signature	Trigger Condition
Bank__NotAdmin	()	Caller is not the contract administrator
Bank__InsufficientBalance	(uint256 available, uint256 required)	Attempting to withdraw or transfer more than user balance
Bank__MaxBalanceExceeded	(uint256 currentBalance, uint256 incoming, uint256 limit)	Operation exceeds the maximum allowed account cap
Bank__InvalidAddress	()	Supplying address(0) as recipient or admin
Bank__ZeroAmount	()	Submitting transactions with 0 value
Bank__TransferFailed	()	Low-level .call execution reverted



Deployment & Interaction (Remix IDE)
Open CryptoBank.sol in Remix and compile with Solidity 0.8.36.
Under Deploy & Run Transactions:
maxBalance_: Initial account cap in Wei (e.g., 5000000000000000000 for 5 ETH).
admin_: Your administrator wallet address.
Click Transact to deploy.
Interactions:
Deposit: Set Value field (e.g., 1 Ether) and call deposit().
Withdraw: Keep Value at 0 Wei and pass the withdrawal amount in Wei to withdraw(amount_).
Internal Transfer: Keep Value at 0 Wei and call transferInternal(recipient, amount).
