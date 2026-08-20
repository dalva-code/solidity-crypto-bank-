// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

// @title CryptoBank - Decentralized Multi-User Vault
// @author David (dalva-code)
// @notice Implements secure deposits, withdrawals, internal transfers, and account cap limits.

// --- Custom Errors (Gas Optimization) ---
error Bank__NotAdmin();
error Bank__InsufficientBalance(uint256 available, uint256 required);
error Bank__MaxBalanceExceeded(uint256 currentBalance, uint256 incoming, uint256 limit);
error Bank__InvalidAddress();
error Bank__ZeroAmount();
error Bank__TransferFailed();

contract CryptoBank {
    // --- State Variables ---
    address public immutable admin;
    uint256 public maxBalance;
    mapping(address => uint256) public userBalance;

    // --- Events ---
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, address indexed recipient, uint256 amount);
    event InternalTransfer(address indexed sender, address indexed recipient, uint256 amount);
    event MaxBalanceUpdated(uint256 oldLimit, uint256 newLimit);

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Bank__NotAdmin();
        _;
    }

    constructor(uint256 maxBalance_, address admin_) {
        if (admin_ == address(0)) revert Bank__InvalidAddress();
        maxBalance = maxBalance_;
        admin = admin_;
    }

    // --- External Functions ---

    /// @notice Deposits native ETH into the caller's bank account.
    function deposit() public payable {
        if (msg.value == 0) revert Bank__ZeroAmount();
        if (userBalance[msg.sender] + msg.value > maxBalance) {
            revert Bank__MaxBalanceExceeded(userBalance[msg.sender], msg.value, maxBalance);
        }

        userBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraws ETH from the sender's bank balance to their own wallet.
    /// @param amount_ Amount in Wei to withdraw.
    function withdraw(uint256 amount_) external {
        _withdrawTo(msg.sender, amount_);
    }

    /// @notice Withdraws ETH from the sender's bank balance to a specific recipient address.
    /// @param recipient_ Destination address.
    /// @param amount_ Amount in Wei to withdraw.
    function withdrawTo(address recipient_, uint256 amount_) external {
        if (recipient_ == address(0)) revert Bank__InvalidAddress();
        _withdrawTo(recipient_, amount_);
    }

    /// @notice Internal transfer between bank accounts without leaving the contract.
    /// @param recipient_ Internal bank user to credit.
    /// @param amount_ Amount in Wei to transfer.
    function transferInternal(address recipient_, uint256 amount_) external {
        if (recipient_ == address(0) || recipient_ == msg.sender) revert Bank__InvalidAddress();
        if (amount_ == 0) revert Bank__ZeroAmount();
        if (userBalance[msg.sender] < amount_) {
            revert Bank__InsufficientBalance(userBalance[msg.sender], amount_);
        }
        if (userBalance[recipient_] + amount_ > maxBalance) {
            revert Bank__MaxBalanceExceeded(userBalance[recipient_], amount_, maxBalance);
        }

        // Checks-Effects-Interactions (CEI)
        userBalance[msg.sender] -= amount_;
        userBalance[recipient_] += amount_;

        emit InternalTransfer(msg.sender, recipient_, amount_);
    }

    /// @notice Updates the maximum individual account cap.
    /// @param newMaxBalance_ New ceiling in Wei.
    function modifyMaxBalance(uint256 newMaxBalance_) external onlyAdmin {
        emit MaxBalanceUpdated(maxBalance, newMaxBalance_);
        maxBalance = newMaxBalance_;
    }

    // --- Internal Logic ---

    function _withdrawTo(address recipient_, uint256 amount_) internal {
        if (amount_ == 0) revert Bank__ZeroAmount();
        if (amount_ > userBalance[msg.sender]) {
            revert Bank__InsufficientBalance(userBalance[msg.sender], amount_);
        }

        // 1. Effects (State update before external call prevents Reentrancy)
        userBalance[msg.sender] -= amount_;

        // 2. Interaction
        (bool success, ) = recipient_.call{value: amount_}("");
        if (!success) revert Bank__TransferFailed();

        emit Withdraw(msg.sender, recipient_, amount_);
    }

    // --- Fallbacks ---
    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    // --- View Functions ---
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
