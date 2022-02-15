// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Fees.sol";
 
contract TicketVault is Context, Ownable, Fees {
    using SafeERC20 for IERC20;

    /// @notice enum Status contains multiple status.
    enum Status { Collecting, Staking, Completed }

    struct VaultInfo {
        Status status; // vault status
        uint256 totalVaultShares; // total tokens deposited into Vault.
        uint256 stakingPeriod; // the timestamp length of staking vault.
        uint256 startTimestamp;  // block.number when the vault start accouring rewards. 
        uint256 stopTimestamp; // the block.number to end the staking vault.
        uint256 rewardRate; // rewardRate is totalVaultRewards / stakingPeriod.
        uint256 ratePerStakedToken; // rewardRatePerStakedToken is rewardRate / totalVaultShares   
        uint256 remainingVaultRewards; // remaining rewards for this vault.        
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
    }
    
    struct UserInfo {
        address account;
        uint256 totalUserShares; // total user staked in vault.
        uint256 rewards;
    }

    IERC20 public token;
    VaultInfo public vault;

    mapping (address => UserInfo) public user;

    error NotAuthorized();
    error NoZeroValues();
    error MaxStaked();
    error DepositFailed();
    error WithdrawFailed();
    error NotCollecting();
    error NotStaking();
    error NotCompleted();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 Rewards);
    event StakingStarted(uint256 indexed startTimestamp, uint256 indexed stopTimestamp, uint256 ratePerStakedToken);
    event StakingFinished(uint256 indexed stopTimestamp, uint256 ratePerStakedToken);

    /// @notice modifier checks that user is staking.
    modifier isUser(address account) {
        if (user[_msgSender()].account != account) revert NotAuthorized();
        _;
    }

    /// @notice modifier checks that contract is status collecting.
    modifier isCollecting() {
        if (vault.status != Status.Collecting) revert NotCollecting();
        _;
    }

    /// @notice modifier checks that staking has status started.
    modifier isStaking() {
        if (vault.status != Status.Staking) revert NotStaking();
        _;
    }

    /// @notice modifier checks that contract is status completed.
    modifier isCompleted() {
        if (vault.status != Status.Completed) revert NotCompleted();
        _;
    }

    /// @notice modifier checks for zero values.
    modifier noZeroValues(uint256 amount) {
        if (_msgSender() == address(0) || amount <= 0) revert NoZeroValues();
        _;
    }

    /// @notice modifier sets a max limit to 1 million tokens staked per user.
    modifier limiter(uint256 amount) {
        if (user[_msgSender()].totalUserShares > 0){
            uint256 staking = (user[_msgSender()].totalUserShares += amount);
            if (staking > 1000000000000000000000000) revert MaxStaked();
        }
        _;
    }

    constructor(
        IERC20 _token, 
        address _feeAddress
    ) {
        token = _token;
        feeAddress = _feeAddress;
        vault.stakingPeriod = 13 weeks;
        vault.status = Status.Collecting;
    }

    /// @notice receive function reverts and returns the funds to the sender.
    receive() external payable {
        revert("not payable receive");
    }

    function balance(address account) external view returns (uint256) {
        return token.balanceOf(account);
    }

    /// @notice Add reward amount to the vault.
    /// @dev Restricted to onlyOwner.  
    function addRewards(uint256 _amount) external onlyOwner {
        vault.totalVaultRewards = _amount;
        vault.remainingVaultRewards = _amount;
        vault.rewardRate = (vault.totalVaultRewards / vault.stakingPeriod);
        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /// @notice Deposit funds into vault.
    /// @param _amount The amount to deposit.
    function deposit(uint256 _amount) external isCollecting limiter(_amount) noZeroValues(_amount) {
        user[_msgSender()].account = _msgSender();
        user[_msgSender()].totalUserShares += _amount;
        vault.totalVaultShares += _amount;
        vault.ratePerStakedToken = _recalculateRatePerStakedToken();
        
        token.safeTransferFrom(_msgSender(), address(this), _amount);
        emit Deposit(_msgSender(), _amount);
    }
    
    /// @notice Exit users funds from vault while collecting. ATT. 7% early withdraw fee.
    function exitCollecting() external isUser(_msgSender()) isCollecting {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = user[_msgSender()].totalUserShares;
        user[_msgSender()].totalUserShares = 0;

        (uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);
        
        // Pay 7% withdrawFee before withdraw.
        if (!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
        if(!_withdraw(address(_msgSender()), _withdrawAmount)) revert WithdrawFailed();
        
        vault.totalVaultShares -= _totalUserShares;
        vault.ratePerStakedToken = _recalculateRatePerStakedToken();
        user[_msgSender()].account = address(0);
        
        emit ExitWithFees(_msgSender(), _withdrawAmount, _feeAmount);
    }

    /// @notice Exit funds from vault while staking. ATT. 7% early withdraw fee.
    function exitStaking() external isUser(_msgSender()) isStaking {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = user[_msgSender()].totalUserShares;
        user[_msgSender()].totalUserShares = 0;

        (uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);

        // if withdrawPenaltyPeriod is over, calculate user rewards.
        if (block.timestamp >= (vault.startTimestamp + withdrawPenaltyPeriod)) {
            (, uint256 _pendingUserReward) = _getUserReward(_totalUserShares);
            user[_msgSender()].rewards = _pendingUserReward;
            vault.remainingVaultRewards -= _pendingUserReward;
            _withdrawAmount += _pendingUserReward;
        }

        if(!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
        if(!_withdraw(_msgSender(), _withdrawAmount)) revert WithdrawFailed();
        
        vault.totalVaultShares -= _totalUserShares;

        vault.ratePerStakedToken = _recalculateRatePerStakedToken();
        user[_msgSender()].account = address(0);
        
        emit ExitWithFees(_msgSender(), _withdrawAmount, _feeAmount);
    }

    /// @notice Remove stake and rewards without extra fees.
    function withdraw() external isUser(_msgSender()) isCompleted {
        // require(_msgSender() != address(0), "Not zero adress");
        
        uint256 _totalUserShares =  user[_msgSender()].totalUserShares;
        user[_msgSender()].totalUserShares = 0;
    
        (, uint256 _pendingUserReward) = _getUserReward(_totalUserShares);
        user[_msgSender()].rewards = _pendingUserReward;
        vault.remainingVaultRewards -= _pendingUserReward;
        
        //uint256 _withdrawAmount = (_totalUserShares + _pendingUserReward);

        token.safeTransfer(_msgSender(), _pendingUserReward);
        if(!_withdraw(_msgSender(), _totalUserShares)) revert WithdrawFailed();
        
        vault.totalVaultShares -= _totalUserShares;

        user[_msgSender()].account = address(0);
        emit Withdraw(_msgSender(), _totalUserShares, _pendingUserReward);
    }

    /// @notice Set the status to Started.
    function startVault() external isCollecting onlyOwner {
        vault.status = Status.Staking;
        vault.startTimestamp = block.timestamp;
        vault.stopTimestamp = vault.startTimestamp + vault.stakingPeriod;
        vault.ratePerStakedToken = _recalculateRatePerStakedToken();
        withdrawFeePeriod = 13 weeks; // 3 months fee period 
        withdrawPenaltyPeriod = 2 weeks; // 14 days penalty period

        emit StakingStarted(vault.startTimestamp, vault.stopTimestamp, vault.ratePerStakedToken);
    }

    /// @notice Set the status to completed.
    function stopVault() external isStaking onlyOwner {
        vault.status = Status.Completed;
        vault.stopTimestamp = block.timestamp;
        vault.stakingPeriod = vault.stopTimestamp - vault.startTimestamp;
        vault.rewardRate = vault.totalVaultRewards / vault.stakingPeriod;
        vault.ratePerStakedToken = _recalculateRatePerStakedToken();
        emit  StakingFinished(vault.stopTimestamp, vault.ratePerStakedToken);
    }

    /// @notice Internal function to return the userReward.
    /// @dev used in exit() and withdraw() to calculate user rewards.
    function _getUserReward(uint256 _totalUserShares)
        internal
        view 
        returns (uint256, uint256) 
    {
        uint256 _userStakingPeriod = (block.timestamp - vault.startTimestamp);
        uint256 _pendingUserReward = (vault.ratePerStakedToken * _totalUserShares) * _userStakingPeriod;

        return (_userStakingPeriod, _pendingUserReward);
    }
    
    /// @notice Internal function recalculates the rate per token staked after every exit().
    function _recalculateRatePerStakedToken() internal view returns (uint256) {
        return (vault.rewardRate / vault.totalVaultShares);
    }
/* 
    /// @notice Internal function to deposit funds to vault.
    /// @param _from The from address that deposits the funds.
    /// @param _amount The amount to be deposited.
    /// @return true if vaild.
    function _deposit(address _from, uint256 _amount) private returns (bool) {
        token.safeTransferFrom(_from, address(this), _amount);
    }
 */
    /// @notice Internal function to withdraw funds from the vault.
    /// @param _to The address that receives the withdrawn funds.
    /// @param _amount The amount to be withdrawn.
    /// @return true if vaild.
    function _withdraw(address _to, uint256 _amount) private returns (bool) {
        token.safeTransfer(address(_to), _amount);
        return true;
    }

}