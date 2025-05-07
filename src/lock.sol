// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title MultiTokenLockWithWhitelist
 * @dev Lock contract with multi-token support and token whitelist management.
 */
contract MultiTokenLock is Ownable {
    using SafeERC20 for IERC20;

    struct LockInfo {
        uint256 amount;
        uint256 unlockTime;
    }

    /// user => token => locks[]
    mapping(address => mapping(address => LockInfo[])) private userLocks;

    /// token => total locked amount
    mapping(address => uint256) public totalLocked;

    /// whitelisted tokens
    mapping(address => bool) public allowedTokens;

    event Locked(address indexed user, address indexed token, uint256 amount, uint256 unlockTime);
    event Unlocked(address indexed user, address indexed token, uint256 amount);
    event TokenAllowed(address token, bool allowed);

    // ------------------------
    // Admin Functions
    // ------------------------

    function setTokenAllowed(address token, bool allowed) external onlyOwner {
        require(token != address(0), "Invalid token");
        allowedTokens[token] = allowed;
        emit TokenAllowed(token, allowed);
    }

    // ------------------------
    // Core Lock Logic
    // ------------------------

    function lock(address token, uint256 amount, uint256 lockDuration) external {
        require(allowedTokens[token], "Token not allowed");
        require(amount > 0, "Amount zero");
        require(lockDuration > 0, "Duration zero");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 unlockAt = block.timestamp + lockDuration;
        userLocks[msg.sender][token].push(LockInfo({
            amount: amount,
            unlockTime: unlockAt
        }));

        totalLocked[token] += amount;

        emit Locked(msg.sender, token, amount, unlockAt);
    }

    function unlock(address token, uint256 index) external {
        LockInfo[] storage locks = userLocks[msg.sender][token];
        require(index < locks.length, "Invalid index");

        LockInfo memory info = locks[index];
        require(block.timestamp >= info.unlockTime, "Still locked");
        require(info.amount > 0, "Nothing to unlock");

        uint256 amount = info.amount;

        // Remove the lock
        uint256 last = locks.length - 1;
        locks[index] = locks[last];
        locks.pop();

        totalLocked[token] -= amount;

        IERC20(token).safeTransfer(msg.sender, amount);
        emit Unlocked(msg.sender, token, amount);
    }

    function getLocks(address user, address token) external view returns (LockInfo[] memory) {
        return userLocks[user][token];
    }
}