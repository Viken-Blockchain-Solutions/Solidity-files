// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TicketVault is Context, Ownable {
    using SafeERC20 for IERC20;

    /// @notice enum Status contains multiple status.
    enum Status { Collecting, Started, Completed }

    struct VaultInfo {
        Status status; // vault status
        uint256 rewardsPerBlock; // rewards to be released to the vault each block. 
        uint256 totalVaultShares; // total tokens deposited into Vault.
        uint256 startBlock;  // block.number when the vault start accouring rewards. 
        uint256 stopBlock; // the block.number to end the staking vault.
        uint256 lastRewardBlock; // the last block rewards was updated.
        uint256 pendingVaultRewards; // pending rewards for this vault.        
        uint256 remainingRewards; // remaining rewards for this vault.        
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
    }
    
    struct UserInfo {
        address user;
        uint256 totalUserShares; // total user staked in vault.
        uint256 userPercentOfVault; // percentage of total staked.
        uint256 lastDepositTime; // ?? last time deposited funds.
        uint256 lastClaimBlock; // 
        uint256 totClaimed;
    }

    IERC20 public token;
    address public feeAddress;
    uint256 public constant withdrawFee = 700; // 7% withdraw fee.
    uint256 public withdrawFeePeriod; // 12 weeks
    uint256 public withdrawPenaltyPeriod; // 14 days;

    VaultInfo public vault;
    mapping (address => UserInfo) public users;

    error NotAuthorized();
    error JustClaimed();

    error DepositFailed();
    error WithdrawFailed();
    error WithdrawFeesFailed();
    error FailedToClaim();
   
    error NotStarted();
    error NotCompleted();
    error NotCollecting();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event WithdrawWithFees(address indexed user, uint256 amount, uint256 fees);
    event Claimed(address indexed user, uint256 amount);
    event StakingStarted();
    event StakingFinished();

    constructor(
        IERC20 _token, 
        address _feeAddress, 
        uint256 _rewardsPerBlock
    ) {
        token = _token;
        feeAddress = _feeAddress;
        vault.status = Status.Collecting;
        vault.rewardsPerBlock = _rewardsPerBlock;
        vault.lastRewardBlock =  block.number;
    }

    /// @notice modifier checks that user can only claim every 24 hours.
    modifier claimable() {
        uint256 nextClaim = users[_msgSender()].lastClaimBlock + 6500;
        if (block.timestamp < nextClaim) revert JustClaimed();
        _;
    }

    /// @notice modifier checks that user is staking.
    modifier isUser() {
        if (_msgSender() != users[_msgSender()].user &&
            users[_msgSender()].totalUserShares > 0
        ) revert NotAuthorized();
        _;
    }

    /// @notice modifier checks that staking has status started.
    modifier isStaking() {
        if (vault.status != Status.Started) revert NotStarted();
        _;
    }

    /// @notice modifier checks that contract is status collecting.
    modifier isCollecting() {
        if (vault.status != Status.Collecting) revert NotCollecting();
        _;
    }

    /// @notice modifier checks that contract is status completed.
    modifier isCompleted() {
        if (vault.status != Status.Completed) revert NotCompleted();
        _;
    }

    /// @notice modifier checks that contract is status completed.
    modifier updateVault() {
        (uint256 _currentRewards) = _getPendingVaultRewards();
            
        vault.remainingRewards -= _currentRewards;
        vault.pendingVaultRewards += _currentRewards;
        vault.lastRewardBlock = block.number;
        _;
    }

    /// @notice Add reward amount to the vault.
    /// @dev Restricted to onlyOwner.  
    function addRewards(uint256 _amount) external onlyOwner {
        vault.totalVaultRewards = _amount;
        vault.remainingRewards = _amount;

        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /// @notice Deposit funds into vault.
    /// @param _amount The amount to deposit.
    function deposit(uint256 _amount) external isCollecting {
        
        if (!_deposit(_msgSender(), _amount)) revert DepositFailed();

        vault.totalVaultShares += _amount;
        users[_msgSender()].user = address(_msgSender());
        users[_msgSender()].totalUserShares += _amount;
        users[_msgSender()].lastDepositTime = block.timestamp;
    }
    
    /// @notice EarlyWithdraw funds from vault. ATT. 7% early withdraw fee.
    function earlyWithdraw() external isUser isCollecting isStaking updateVault {
        require(_msgSender() != address(0), "Not zero address");
        uint256 _feeAmount;
        uint256 _withdrawAmount;
        uint256 _totalUserShares = users[_msgSender()].totalUserShares;
        users[_msgSender()].totalUserShares = 0;
        vault.totalVaultShares -= _totalUserShares;

        // if Vault status is collecting. 
        // Pay 7% withdrawFee before withdraw, No rewards!
        if (vault.status == Status.Collecting) {
            (_feeAmount, _withdrawAmount) = _calculateFee(_totalUserShares);
            if (!_withdraw(address(feeAddress), _feeAmount)) revert WithdrawFeesFailed();
            if(!_withdraw(_msgSender(), _withdrawAmount)) revert WithdrawFailed();
        }

        // if Vault status is started (ongoing).
        // Pay 7% withdraw fee from stake and reward before withdraw.
        if (vault.status == Status.Started) {
            (, uint256 _pendingUserReward) = _calculateUserReward();
            vault.pendingVaultRewards -= _pendingUserReward;

            (_feeAmount, _withdrawAmount) = _calculateFee(_totalUserShares + _pendingUserReward);
           
            if(!_withdraw(address(feeAddress), _feeAmount)) revert WithdrawFeesFailed();
            if(!_withdraw(_msgSender(), _withdrawAmount)) revert WithdrawFailed();
        }

        assert(users[_msgSender()].totalUserShares == 0);
        emit WithdrawWithFees(_msgSender(), _withdrawAmount, _feeAmount);

    }

    /// @notice Remove stake and rewards without extra fees.
    function collectStakeAndRewards() external isUser isCompleted updateVault {
        require(_msgSender() != address(0), "Not zero adress");
        (uint256 _userPercentOfVault, uint256 _pendingUserReward) = _calculateUserReward();
        vault.pendingVaultRewards -= _pendingUserReward;
        
        uint256 _totalUserShares =  users[_msgSender()].totalUserShares;
        users[_msgSender()].totalUserShares = 0;
        users[_msgSender()].userPercentOfVault = _userPercentOfVault;
        users[_msgSender()].totClaimed += _pendingUserReward;
        users[_msgSender()].lastClaimBlock = block.number;
        
        assert(users[_msgSender()].totalUserShares == 0);

        if(!_withdraw(_msgSender(), (_totalUserShares + _pendingUserReward))) revert WithdrawFailed();
        emit Withdraw(_msgSender(), (_totalUserShares + _pendingUserReward));
    }

    /// @notice A function to set the status.
    function startVault(uint256 _stopBlock) external isCollecting onlyOwner {
        vault.status = Status.Started;
        vault.startBlock = block.number;
        vault.stopBlock = _stopBlock;
        vault.lastRewardBlock = block.number;
        withdrawFeePeriod = 13 weeks; // 3 months fee period 
        withdrawPenaltyPeriod = 14 days; // penalty period

        emit StakingStarted();
    }

    /// @notice Set the status to completed.
    function stopVault() external isStaking onlyOwner updateVault {
        vault.status = Status.Completed;
        vault.stopBlock = block.number;

        emit  StakingFinished();
    }

    /// @notice A user can claim their pendingRewards.
    function claim() external isUser isStaking claimable updateVault {
        require(vault.pendingVaultRewards > 0, "No pending rewards");
        (uint256 _userPercentOfVault, uint256 _pendingUserReward) = _calculateUserReward();
        vault.pendingVaultRewards -= _pendingUserReward;

        users[msg.sender].userPercentOfVault = _userPercentOfVault;
        users[msg.sender].totClaimed += _pendingUserReward;
        users[msg.sender].lastClaimBlock = block.number;

        if (!_withdraw(_msgSender(), _pendingUserReward)) revert FailedToClaim();

        emit Claimed(_msgSender(), _pendingUserReward);
    }

    /// @notice Get UserInformation.
    /// @return users Information from users mapping.
    function getUserInfo() external view isUser returns (address, uint256, uint256, uint256, uint256, uint256) {
        return (
            users[_msgSender()].user,
            users[_msgSender()].totalUserShares,
            users[_msgSender()].userPercentOfVault,
            users[_msgSender()].lastDepositTime,
            users[_msgSender()].lastClaimBlock,
            users[_msgSender()].totClaimed
        );
    } 

    function _getPendingVaultRewards() private view returns (uint256) {
        uint256 _pendingVaultRewards = vault.rewardsPerBlock * (block.number - vault.lastRewardBlock);
        return (_pendingVaultRewards);
    }

    /// @notice Internal function to calculate the early withdraw fees.
    /// @notice return feeAmount and withdrawAmount.
    function _calculateFee(uint256 _amount) private pure returns (uint256 feeAmount, uint256 withdrawAmount) {
        feeAmount = _amount * withdrawFee / 10000;
        withdrawAmount = _amount - feeAmount; 
    }

    function _calculateUserReward() private view returns (uint256 userPercentOfVault, uint256 pendingUserReward) {        
        userPercentOfVault = (users[msg.sender].totalUserShares * 100) / vault.totalVaultShares;
        pendingUserReward = (vault.pendingVaultRewards * userPercentOfVault) / 100;
    }

    /// @notice Internal function to deposit funds to vault.
    /// @param _from The from address that deposits the funds.
    /// @param _amount The amount to be deposited.
    /// @return true if vaild.
    function _deposit(address _from, uint256 _amount) private returns (bool) {
        token.safeTransferFrom(_from, address(this), _amount);
        emit Deposit(_from, _amount);
        return true;
    }

    /// @notice Internal function to withdraw funds from the vault.
    /// @param _to The address that receives the withdrawn funds.
    /// @param _amount The amount to be withdrawn.
    /// @return true if vaild.
    function _withdraw(address _to, uint256 _amount) private returns (bool) {
        token.safeTransfer(_to, _amount);
        return true;
    }

}