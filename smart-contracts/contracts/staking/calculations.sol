// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract calculations {
 
    address private feeAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    uint256 public constant withdrawFee = 700; // 7% withdraw fee.
    uint256 public withdrawFeePeriod = 91 days; // 13 weeks
    uint256 public withdrawPenaltyPeriod = 14 days; // 14 days;

    struct VaultInfo {
        uint256 rewardsPerBlock;// rewards to be released to the vault each block. 
        uint256 totalVaultShares; // 3.5 mill tokens deposited into Vault.
        uint256 startBlock;  // block.number when the vault start accouring rewards. 
        uint256 stopBlock;  // the block.number to end the staking vault.
        uint256 lastRewardUpdateBlock; // the last block rewards was updated.
        uint256 pendingVaultRewards; // pending rewards for this vault.        
        uint256 remainingRewards; // remaining rewards for this vault.        
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
        }

    struct UserInfo {
        address user;
        uint256 totalUserShares;
        uint256 userPercentOfVault;
        uint256 lastDepositTime;
        uint256 pendingUserRewards;
        uint256 lastClaimTime;
        uint256 totClaimed;
    }

    mapping (address => UserInfo) public users;
    VaultInfo public vault;

    constructor() {
        vault.rewardsPerBlock = 33812307000000000000; // 33.812307 reward per block
        vault.totalVaultShares = 9000000000000000000000; // 9 000 shares 
        vault.startBlock = block.number;
        vault.stopBlock = vault.startBlock + 100;
        vault.lastRewardUpdateBlock = vault.startBlock;
        vault.remainingRewards = vault.totalVaultRewards;
        addRewards(2000000000000000000000000); // 2 000 000 reward
    }

 

    function getUserInfo() external view returns (
        address user,
        uint256 totalUserShares,
        uint256 lastDepositTime,
        uint256 lastClaimTime,
        uint256 totClaimed
    ) {
        return (
            users[msg.sender].user,
            users[msg.sender].totalUserShares,
            users[msg.sender].lastDepositTime,
            users[msg.sender].lastClaimTime,
            users[msg.sender].totClaimed
        );
    }

    function _calculateFee(uint256 _amount) public pure returns(uint256, uint256) {
        uint256 feeAmount = (_amount * withdrawFee) / 10000;
        uint256 withdrawAmount = (_amount - feeAmount);

        return (feeAmount, withdrawAmount); 
    }

    function getPendingVaultRewards() public view returns (uint256) {
        uint256 _pendingVaultRewards = vault.rewardsPerBlock * (block.number - vault.lastRewardUpdateBlock);
        return _pendingVaultRewards;
    }

    modifier updateVault() {
        (uint256 _currentRewards) = getPendingVaultRewards();
            
        vault.remainingRewards -= _currentRewards;
        vault.pendingVaultRewards += _currentRewards;
        vault.lastRewardUpdateBlock = block.number;
        _;
    }

    function addRewards(uint256 _amount) internal {
        vault.remainingRewards +=  _amount;
        vault.totalVaultRewards +=  _amount;
    }

    function deposit() external {
        uint256 _amount = 1000000000000000000000; // 1000 shares
        vault.totalVaultShares += _amount; // is 10 000 shares

        users[msg.sender].user = address(msg.sender);
        users[msg.sender].totalUserShares += _amount;
        users[msg.sender].lastDepositTime = block.timestamp;
        users[msg.sender].userPercentOfVault = (users[msg.sender].totalUserShares * 100) / vault.totalVaultShares;

        
    }


    function claim() updateVault external {
        (,uint256 _pendingUserReward) = _calculateClaim();
        vault.pendingVaultRewards -= _pendingUserReward;

        users[msg.sender].userPercentOfVault = block.timestamp;
        users[msg.sender].lastClaimTime = block.timestamp;
        users[msg.sender].totClaimed += _pendingUserReward;
    }

    function _calculateClaim() public view returns(uint256, uint256) {
        require(vault.pendingVaultRewards > 0, "No pending rewards");
        
        uint256 _userPercentOfVault = (users[msg.sender].totalUserShares * 100) / vault.totalVaultShares;
        uint256 _pendingUserReward = (vault.pendingVaultRewards * _userPercentOfVault) / 100;

        return (_userPercentOfVault, _pendingUserReward);
    }

}
