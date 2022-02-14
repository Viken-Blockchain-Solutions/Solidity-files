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
    enum Status { Collecting, Started, Completed }

    struct VaultInfo {
        Status status; // vault status
        uint256 totalVaultShares; // total tokens deposited into Vault.
        uint256 stakingPeriod;
        uint256 startTimestamp;  // block.number when the vault start accouring rewards. 
        uint256 stopTimestamp; // the block.number to end the staking vault.
        uint256 rewardRate; // totalVaultReward / stakingPeriod
        uint256 ratePerStakedToken;      
        uint256 remainingVaultRewards; // remaining rewards for this vault.        
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
    }
    
    struct UserInfo {
        address account;
        uint256 totalUserShares; // total user staked in vault.
    }

    IERC20 public token;
    VaultInfo public vault;

    mapping (address => UserInfo) public user;

    error NotAuthorized();
    error NoZeroValues();

    error DepositFailed();
    error WithdrawFailed();
    error FailedToClaim();
   
    error NotStarted();
    error NotCompleted();
    error NotCollecting();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    event StakingStarted();
    event StakingFinished();

    constructor(
        IERC20 _token, 
        address _feeAddress,
        uint256 _totalVaultRewards
    ) {
        token = _token;
        feeAddress = _feeAddress;
        vault.stakingPeriod = 13 weeks;
        vault.status = Status.Collecting;
        vault.totalVaultRewards = _totalVaultRewards;
        vault.remainingVaultRewards = _totalVaultRewards;
        vault.rewardRate = (vault.totalVaultRewards / vault.stakingPeriod);
    }

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
        if (vault.status != Status.Started) revert NotStarted();
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

    /// @notice Deposit funds into vault.
    /// @param _amount The amount to deposit.
    function deposit(uint256 _amount) external isCollecting noZeroValues(_amount) {
        user[_msgSender()].account = _msgSender();
        user[_msgSender()].totalUserShares += _amount;
        vault.totalVaultShares += _amount;
        
        if (!_deposit(_msgSender(), _amount)) revert DepositFailed();
    }
    
    /// @notice exit funds from vault. ATT. 7% early withdraw fee.
    function exit() external isUser(_msgSender()) {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = user[_msgSender()].totalUserShares;
        user[_msgSender()].totalUserShares = 0;

        (uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);
        
        // if Vault status is collecting. 
        // Pay 7% withdrawFee before withdraw, No rewards!
        if (vault.status == Status.Collecting) {
            if (!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
            if(!_withdraw(_msgSender(), _withdrawAmount)) revert WithdrawFailed();
        }

        // if Vault status is started (ongoing).
        // Pay 7% withdraw fee from stake not pending rewards, before withdraw.
        if (vault.status == Status.Started) {
            (uint256 _pendingUserReward) = _getUserReward(_totalUserShares);
            vault.remainingVaultRewards -= _pendingUserReward;
            _withdrawAmount += _pendingUserReward;

            if(!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
            if(!_withdraw(_msgSender(), _withdrawAmount)) revert WithdrawFailed();
        }
        
        user[_msgSender()].account = address(0);
        vault.totalVaultShares -= _totalUserShares;

        _recalculateRatePerTokenStored();
        
        emit ExitWithFees(_msgSender(), _withdrawAmount, _feeAmount);
    }

    /// @notice Remove stake and rewards without extra fees.
    function collectStakeAndRewards() external isUser(_msgSender()) isCompleted {
        require(_msgSender() != address(0), "Not zero adress");
        
        uint256 _totalUserShares =  user[_msgSender()].totalUserShares;
        user[_msgSender()].totalUserShares = 0;
    
        (uint256 _pendingUserReward) = _getUserReward(_totalUserShares);
        vault.remainingVaultRewards -= _pendingUserReward;
        
        if(!_withdraw(_msgSender(), (_totalUserShares + _pendingUserReward))) revert WithdrawFailed();
        
        user[_msgSender()].account = address(0);
        
        vault.totalVaultShares -= _totalUserShares;
        _recalculateRatePerTokenStored();

        emit Withdraw(_msgSender(), (_totalUserShares + _pendingUserReward));
    }

    /// @notice A function to set the status to Started.
    function startVault() external isCollecting onlyOwner {
        vault.status = Status.Started;
        vault.startTimestamp = block.timestamp;
        vault.stopTimestamp = vault.startTimestamp + vault.stakingPeriod;
        vault.ratePerStakedToken = (vault.rewardRate / vault.totalVaultShares);
        withdrawFeePeriod = 13 weeks; // 3 months fee period 
        withdrawPenaltyPeriod = 2 weeks; // 14 days penalty period

        emit StakingStarted();
    }

    /// @notice Set the status to completed.
    function stopVault() external isStaking onlyOwner {
        vault.status = Status.Completed;
        vault.stopTimestamp = block.timestamp;

        emit  StakingFinished();
    }

    /// @notice Get UserInformation.
    function getUserInfo() external view isStaking isUser(_msgSender()) returns (
        address account, 
        uint256 totalUserShares, 
        uint256 pendingUserRewards
        ) 
    {
        return (
            user[_msgSender()].account,
            user[_msgSender()].totalUserShares,
            _getUserReward(user[_msgSender()].totalUserShares)
        );
    } 

    /// @notice modifier calculates the pendingUserReward.
    function _getUserReward(uint256 _totalUserShares) private view returns (uint256 pendingUserReward) {
        uint256 userStakingPeriod = (block.timestamp - vault.startTimestamp);
        pendingUserReward = (vault.ratePerStakedToken * _totalUserShares) * userStakingPeriod;
    }
    
    /// @notice modifier recalculates the rate per token stored after a withdraw.
    function _recalculateRatePerTokenStored() private {
        vault.ratePerStakedToken = (vault.rewardRate / vault.totalVaultShares);
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