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
Checks-Effects-Interactions (CEI) Pattern: Guarantees immunity against Reentrancy attacks by reducing internal accounting state prior to external ETH execution (.call).
Dual Transfer Mechanics:
External Withdrawal (withdraw / withdrawTo): Sends native Ether back to the caller or a third-party recipient address.
Internal Transfer (transferInternal): Zero-overhead ledger transfer between vault accounts modifying contract storage without moving native ETH.
Automated ETH Fallbacks: Dedicated receive() and fallback() methods routing direct incoming Ether straight to user deposits.
Gas Optimization: Replaced expensive revert strings with parameterized top-level Custom Errors.
Storage & Access Control: Immutable admin variable and parameterized maxBalance deposit ceilings.


Custom Errors Reference
Custom Error	Parameter Signature	Trigger Condition
Bank__NotAdmin	()	Caller is not the contract administrator
Bank__InsufficientBalance	(uint256 available, uint256 required)	Attempting to withdraw or transfer more than user balance
Bank__MaxBalanceExceeded	(uint256 currentBalance, uint256 incoming, uint256 limit)	Operation exceeds the maximum allowed account cap
Bank__InvalidAddress	()	Supplying address(0) as recipient or admin
Bank__ZeroAmount	()	Submitting transactions with 0 value
Bank__TransferFailed	()	Low-level .call execution reverted

├── contracts/
│   └── CryptoBank.sol
└── README.md

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
