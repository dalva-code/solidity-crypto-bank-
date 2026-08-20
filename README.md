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
