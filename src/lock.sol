// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenLock
 * @dev A simple lockup contract where users lock ERC20 tokens for a specified duration.
 *      Users can only unlock after the lock period has elapsed.
 */
contract TokenLock is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable lockToken;

    struct LockInfo {
        uint256 amount;      // Amount locked
        uint256 unlockTime;  // Timestamp when tokens become withdrawable
    }

    // Mapping of user => array of locks
    mapping(address => LockInfo[]) private locks;

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Unlocked(address indexed user, uint256 amount);

    /**
     * @param _lockToken Address of the ERC20 token used for locking
     */
    constructor(IERC20 _lockToken) {
        require(address(_lockToken) != address(0), "TokenLock: zero token");
        lockToken = _lockToken;
    }

    /**
     * @notice Lock a given amount of tokens with a lock duration.
     * @param amount The amount of tokens to lock
     * @param lockDuration Duration (in seconds) to lock tokens
     */
    function lock(uint256 amount, uint256 lockDuration) external {
        require(amount > 0, "TokenLock: amount zero");
        require(lockDuration > 0, "TokenLock: duration zero");

        // Transfer tokens from user to contract
        lockToken.safeTransferFrom(msg.sender, address(this), amount);

        // Record lock
        uint256 unlockAt = block.timestamp + lockDuration;
        locks[msg.sender].push(LockInfo({
            amount: amount,
            unlockTime: unlockAt
        }));

        emit Locked(msg.sender, amount, unlockAt);
    }

    /**
     * @notice Unlock tokens for a specific lock index, if unlocked.
     * @param index Index of the lock to withdraw
     */
    function unlock(uint256 index) external {
        require(index < locks[msg.sender].length, "TokenLock: invalid index");

        LockInfo memory info = locks[msg.sender][index];
        require(block.timestamp >= info.unlockTime, "TokenLock: still locked");
        require(info.amount > 0, "TokenLock: nothing to unlock");

        // Remove lock by swapping with last and popping
        uint256 amount = info.amount;
        uint256 last = locks[msg.sender].length - 1;
        locks[msg.sender][index] = locks[msg.sender][last];
        locks[msg.sender].pop();

        // Transfer tokens back to user
        lockToken.safeTransfer(msg.sender, amount);

        emit Unlocked(msg.sender, amount);
    }

    /**
     * @notice Returns all lock records for a user
     * @param user Address to query
     */
    function getLocks(address user) external view returns (LockInfo[] memory) {
        return locks[user];
    }
}
