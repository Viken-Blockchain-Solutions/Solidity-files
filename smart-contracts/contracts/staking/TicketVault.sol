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
        uint256 ratePerStakedToken; // rewardRatePerStakedToken is rewardRate / totalVaultShares.
        uint256 claimedVaultRewards; // claimed rewards for the vault.
        uint256 remainingVaultRewards; // remaining rewards for this vault.        
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
    }
    
    IERC20 public token;
    VaultInfo public vault;
    
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _isStakeholder;

    error NotAuthorized();
    error NoZeroValues();
    error MaxStaked();
    error AddRewardsFailed();
    error DepositFailed();
    error RewardFailed();
    error WithdrawFailed();
    error NotCollecting();  
    error NotStaking();
    error NotCompleted();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 rewards);
    event StakingStarted(
        uint256 indexed startTimestamp,
        uint256 indexed stopTimestamp,
        uint256 ratePerStakedToken
    );
    event StakingFinished(uint256 indexed stopTimestamp, uint256 ratePerStakedToken);

    /// @notice modifier checks that a user is staking.
    modifier isStakeholder(address account) {
        if (_balances[account] == 0) revert NotAuthorized();
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
        if (_balances[_msgSender()] > 0){
            uint256 staking = (_balances[_msgSender()] += amount);
            if (staking > 1000000e18) revert MaxStaked();
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
        withdrawFeePeriod = 13 weeks; // 3 months fee period 
        withdrawPenaltyPeriod = 2 weeks; // 14 days penalty period
        vault.status = Status.Collecting;
    }

    /// @notice receive function reverts and returns the funds to the sender.
    receive() external payable {
        revert("not payable receive");
    }

    function balance(address account) external view returns (uint256) {
        return token.balanceOf(account);
    }

    function userBalance(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice Add reward amount to the vault.
    /// @param amount The amount to deposit in Wei.
    /// @dev Restricted to onlyOwner.  
    function addRewards(uint256 amount) external onlyOwner {
        vault.totalVaultRewards += amount;
        vault.remainingVaultRewards += amount;
        vault.rewardRate = (vault.totalVaultRewards / vault.stakingPeriod) * 1e18;
        if (!_deposit(_msgSender(), amount)) revert AddRewardsFailed();
    }

    /// @notice Deposit funds into vault.
    /// @param amount The amount to deposit.
    function deposit(uint256 amount) external isCollecting limiter(amount) noZeroValues(amount) {
        _balances[_msgSender()] += amount;
        vault.totalVaultShares += amount;
        //vault.ratePerStakedToken = (vault.rewardRate / vault.totalVaultShares);
        
        if (!_deposit(_msgSender(), amount)) revert DepositFailed();
        emit Deposit(_msgSender(), amount);
    }
    
    /// @notice Exit users funds from vault while collecting. ATT. 7% early withdraw fee.
    function exitCollecting() external isStakeholder(_msgSender()) isCollecting {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = _balances[_msgSender()];
        delete _balances[_msgSender()];

        (uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);
        
        // Pay 7% withdrawFee before withdraw.
        if (!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
        if (!_withdraw(address(_msgSender()), _withdrawAmount)) revert WithdrawFailed();
        
        vault.totalVaultShares -= _totalUserShares;
        vault.ratePerStakedToken = (vault.rewardRate / vault.totalVaultShares);

        emit ExitWithFees(_msgSender(), _withdrawAmount, _feeAmount);
    }

    /// @notice Exit funds from vault while staking. ATT. 7% early withdraw fee.
    function exitStaking() external isStakeholder(_msgSender()) isStaking {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = _balances[_msgSender()];
        delete _balances[_msgSender()];

        (uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);

        // if withdrawPenaltyPeriod is over, calculate user rewards.
        if (block.timestamp >= (vault.startTimestamp + withdrawPenaltyPeriod)) {
            uint256 _pendingUserReward = ((
                vault.ratePerStakedToken  / 1e18) * _totalUserShares
            )  * (block.timestamp - vault.startTimestamp);

            vault.remainingVaultRewards -= _pendingUserReward;
            vault.claimedVaultRewards += _pendingUserReward;

            _withdrawAmount += _pendingUserReward;
        }

        // Pay 7% withdrawFee before withdraw.
        if (!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
        if (!_withdraw(address(_msgSender()), _withdrawAmount)) revert WithdrawFailed();

        vault.totalVaultShares -= _totalUserShares;

        emit ExitWithFees(_msgSender(), _withdrawAmount, _feeAmount);
    }

    /// @notice Remove stake and rewards without extra fees.
    function withdraw() external isStakeholder(_msgSender()) isCompleted {
        require(_msgSender() != address(0), "Not zero adress");
        
        uint256 _totalUserShares =  _balances[_msgSender()];
        delete _balances[_msgSender()];
    
        uint256 _pendingUserReward = ((
            vault.ratePerStakedToken / 1e18) * _totalUserShares
        ) * (vault.stopTimestamp - vault.startTimestamp);
        
        if (!_withdraw(_msgSender(), _pendingUserReward)) revert RewardFailed();
        if (!_withdraw(_msgSender(), _totalUserShares)) revert WithdrawFailed();
        
        vault.remainingVaultRewards -= _pendingUserReward;
        vault.claimedVaultRewards += _pendingUserReward;
        vault.totalVaultShares -= _totalUserShares;

        emit Withdraw(_msgSender(), _totalUserShares, _pendingUserReward);
    }

    /// @notice Set the status to Started.
    function startStaking() external isCollecting onlyOwner {
        vault.status = Status.Staking;
        vault.startTimestamp = block.timestamp;
        vault.stopTimestamp = vault.startTimestamp + vault.stakingPeriod;
        vault.ratePerStakedToken = (vault.rewardRate / vault.totalVaultShares);

        emit StakingStarted(vault.startTimestamp, vault.stopTimestamp, vault.ratePerStakedToken);
    }

    /// @notice Set the status to completed.
    function stopStaking() external isStaking onlyOwner {
        vault.status = Status.Completed;
        vault.rewardRate = (vault.remainingVaultRewards/ vault.stakingPeriod) * 1e18;
        vault.ratePerStakedToken = (vault.rewardRate / vault.totalVaultShares);

        emit StakingFinished(vault.stopTimestamp, vault.ratePerStakedToken);
    }
    
    /// @notice Internal function to deposit funds to vault.
    /// @param _from The from address that deposits the funds.
    /// @param _amount The amount to be deposited.
    /// @return true if valid.
    function _deposit(address _from, uint256 _amount) private returns (bool) {
        token.safeTransferFrom(_from, address(this), _amount);
        return true;
    }
 
    /// @notice Internal function to withdraw funds from the vault.
    /// @param _to The address that receives the withdrawn funds.
    /// @param _amount The amount to be withdrawn.
    /// @return true if valid.
    function _withdraw(address _to, uint256 _amount) private returns (bool){
        token.safeTransfer(_to, _amount);
        return true;
    }

}