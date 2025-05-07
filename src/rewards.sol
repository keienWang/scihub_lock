// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeVault is Ownable {
    
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lockMonths;
        bool withdrawn;
    }

    struct UserProjectStake {
        uint256 totalStaked;
        StakeInfo[] records;
    }

    struct ProjectData {
        uint256 totalStaked;
        uint256 totalDonated;
    }

    IERC20 public immutable stakeToken;
    uint256 public constant MIN_LOCK_SECONDS = 30 days;

    // projectId => user => UserProjectStake
    mapping(bytes32 => mapping(address => UserProjectStake)) public userStakes;
    // projectId => ProjectData
    mapping(bytes32 => ProjectData) public projects;

    event Staked(address indexed user, bytes32 indexed projectId, uint256 amount, uint256 lockMonths);
    event Withdrawn(address indexed user, bytes32 indexed projectId, uint256 amount);
    event Donated(bytes32 indexed projectId, uint256 amount);

    constructor(IERC20 _stakeToken) Ownable(msg.sender) {
        stakeToken = _stakeToken;
    }

    function stake(bytes32 projectId, uint256 amount, uint256 lockMonths) external {
        require(lockMonths >= 1, "Minimum 1 month lock required");
        require(amount > 0, "Stake amount must be > 0");

        UserProjectStake storage ups = userStakes[projectId][msg.sender];
        projects[projectId].totalStaked += amount;
        ups.totalStaked += amount;
        ups.records.push(StakeInfo({
            amount: amount,
            startTime: block.timestamp,
            lockMonths: lockMonths,
            withdrawn: false
        }));

        stakeToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, projectId, amount, lockMonths);
    }

    function withdraw(bytes32 projectId, uint256 index) external {
        StakeInfo storage info = userStakes[projectId][msg.sender].records[index];
        require(!info.withdrawn, "Already withdrawn");
        require(block.timestamp >= info.startTime + info.lockMonths * MIN_LOCK_SECONDS, "Still locked");

        info.withdrawn = true;
        userStakes[projectId][msg.sender].totalStaked -= info.amount;
        projects[projectId].totalStaked -= info.amount;
        stakeToken.transfer(msg.sender, info.amount);

        emit Withdrawn(msg.sender, projectId, info.amount);
    }

    function donate(bytes32 projectId, uint256 amount) external {
        require(amount > 0, "Zero donation");
        stakeToken.transferFrom(msg.sender, address(this), amount);
        projects[projectId].totalDonated += amount;
        emit Donated(projectId, amount);
    }

    function getUserTotalStake(bytes32 projectId, address user) external view returns (uint256) {
        return userStakes[projectId][user].totalStaked;
    }

    function getProjectStats(bytes32 projectId) external view returns (uint256 totalStaked, uint256 totalDonated) {
        ProjectData memory pd = projects[projectId];
        return (pd.totalStaked, pd.totalDonated);
    }

    function getUserStakeRecords(bytes32 projectId, address user) external view returns (StakeInfo[] memory) {
        return userStakes[projectId][user].records;
    }
}
