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
    
    IERC20 public token;
    address public feeAddress;
    uint256 public constant withdrawFee = 700; // 7%
    bool public initialized;

    struct Vault {
        Status status; // vault status
        uint256 totalVaultShares; // total tokens deposited into Vault.
        uint256 startBlock;  // block.number when the vault start accouring rewards. 
        uint256 stopBlock; // the block.number to end the staking vault.
        uint256 rewardsPerBlock; // rewards to be realised to the vault each block. 
        uint256 lastRewardBlock; // the last block rewards was updated.
        uint256 pendingRewards; // pending rewards for this vault.        
        uint256 remainingRewards; // remaining rewards for this vault.        
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
        uint256 withdrawFeePeriod; // 12 weeks;
        uint256 withdrawPenaltyPeriod; // 14 days;
    }

    struct UserInfo {
        address user;
        uint256 totUserShares;
        uint256 lastDepositedTime;
        uint256 lastClaimTime;
        uint256 pendingRewards;
    }

    Vault public vault;
    mapping (address => UserInfo) public users;

    error FailedToInitVault();
    error AlreadyInitialized();
    error NotAuthorized();
    error NotEnoughShares();
    error JustClaimed();

    error DepositFailed();
    error WithdrawFailed();
    error CalculateFeesFailed();
    error WithdrawFeesFailed();
    error RewardsLow();
   
    error NotStarted();
    error NotCollecting();
    error VaultCompleted();
    error RewardsCompleted();
   
    event VaultInitialized();
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EarlyWithdraw(address indexed user, uint256 amount, uint256 feeAmount);
    event Rewards(address indexed user, uint256 amount);
    event VaultStarted();
    event VaultFinished();

    constructor(IERC20 _token, address _feeAddress) {
        token = _token;
        feeAddress = _feeAddress;
    }
    
    modifier notInitialized() {
        if (initialized) 
            revert AlreadyInitialized();
        _;
        initialized = true;
    }

    modifier canClaim() {
        uint256 nextClaim = users[_msgSender()].lastClaimTime + 1 days;
        if (block.timestamp < nextClaim) revert JustClaimed();
        _;
    }

    modifier isUser() {
        if (_msgSender() != users[_msgSender()].user) revert NotAuthorized();
        _;
    }

    modifier isStarted() {
        if (vault.status != Status.Started) revert NotStarted();
        _;
    }

    modifier isCollecting() {
        if (vault.status != Status.Collecting) revert NotCollecting();
        _;
    }

    // ethereum mainnet averages 6500 blocksPerDay.
    // 3381230700000000000 _rewardPerBlock.
    function initializeVault(uint256 rewardsPerBlock, uint256 totVaultRewards)
        external 
        onlyOwner
        notInitialized
    {
        vault.status = Status.Collecting;
        vault.rewardsPerBlock = rewardsPerBlock;
        vault.lastRewardBlock =  block.number;
        vault.remainingRewards =  totVaultRewards;
        vault.totalVaultRewards =  totVaultRewards;

        if (!_deposit(_msgSender(), totVaultRewards)) revert FailedToInitVault();
        initialized;
        emit VaultInitialized();
    }

    /// @notice Deposit funds into vault.
    /// @param _amount The amount to deposit.
    /// @return true if vaild.
    function deposit(uint256 _amount) external isCollecting returns (bool) {
        if (!_deposit(_msgSender(), _amount)) revert DepositFailed();

        vault.totalVaultShares += _amount;
        users[_msgSender()].user = address(_msgSender());
        users[_msgSender()].totUserShares += _amount;
        users[_msgSender()].lastDepositedTime = block.timestamp;
        
        return true;
    }
    
    /// @notice Withdraw funds from vault.
    /// @param _amount The amount to withdraw from the vault.
    /// @return true if vaild.
    function withdraw(uint256 _amount) external isUser returns (bool) {
        if (users[_msgSender()].totUserShares < _amount) revert NotEnoughShares();

        uint256 _shares = _amount;
        users[_msgSender()].totUserShares -= _shares;
        vault.totalVaultShares -= _shares;

        // if Vault status is collecting. 
        // Pay 7% withdrawFee before withdraw, No rewards!
        if (vault.status == Status.Collecting) {

            (uint256 _feeAmount, uint256 _withdrawAmount) = _calculateFee(_shares);
            
            if (!_withdraw(feeAddress, _feeAmount)) revert WithdrawFeesFailed();
            require(_withdraw(_msgSender(), _withdrawAmount));
            
            emit EarlyWithdraw(_msgSender(), _withdrawAmount, _feeAmount);

            return true;
        } 

        // if Vault status is started (ongoing).
        // Pay 7% withdraw fee from stake and reward before withdraw.
        if (vault.status == Status.Started) {
            updateVault();
            _distributeUserRewards();

            uint256 _userRewards = users[_msgSender()].pendingRewards;
            users[_msgSender()].pendingRewards = 0;

            (uint256 _feeAmount, uint256 _withdrawAmount) = _calculateFee(_shares + _userRewards);
            
            if(!_withdraw(feeAddress, _feeAmount)) revert WithdrawFeesFailed();
            require(_withdraw(_msgSender(), _withdrawAmount));

            emit EarlyWithdraw(_msgSender(), _withdrawAmount, _feeAmount);

            return true;
        }
        
        // if Vault status is completed (finished).
        // Withdraw stake and rewards without extra fees.
        if (vault.status == Status.Completed) {
            updateVault();
            _distributeUserRewards();
            uint256 _userRewards = users[_msgSender()].pendingRewards;
            users[_msgSender()].pendingRewards = 0;
            
            uint256 withdrawAmount = _shares + _userRewards;
            if(!_withdraw(_msgSender(), withdrawAmount)) revert WithdrawFailed();

            return true;
        }

        return true;
    }

    /// @notice Updates the Vaults pending rewards.
    function updateVault() internal isStarted {
        //if (vault.status == Status.Completed) revert VaultCompleted();
        if (vault.remainingRewards <= uint256(4e18)) revert RewardsLow();

        if (block.number >= vault.stopBlock) {
            vault.status = Status.Completed;
            emit VaultFinished();
        } 

        _pendingVaultRewards();
    }

    /// @notice A setter function to set the status.
    function startVault(uint256 _stopBlock) external isCollecting onlyOwner {
        vault.status = Status.Started;
        vault.startBlock = block.number;
        vault.stopBlock = _stopBlock;
        vault.lastRewardBlock = block.number;
        vault.withdrawFeePeriod = 13 weeks; // fee period 
        vault.withdrawPenaltyPeriod = 14 days; // penalty period

        emit VaultStarted();
    }

    /// @notice A setter function to set the status.
    function stopVault() external isStarted onlyOwner {
        updateVault();
        vault.status = Status.Completed;
        vault.stopBlock = block.number;

        emit  VaultFinished();
    }

    /// @notice A user can claim their pendingRewards.
    function claim() external isUser isStarted canClaim returns (uint256 amount) {
        updateVault();
        _distributeUserRewards();
        
        amount = users[_msgSender()].pendingRewards;
        users[_msgSender()].pendingRewards = 0;

        require(_withdraw(_msgSender(), amount));
        users[_msgSender()].lastClaimTime = block.timestamp;

        emit Rewards(_msgSender(), amount);
    }

    /// @notice Get UserInformation.
    /// @return users Information from users mapping.
    function getUserInfo() external returns (UserInfo memory) {
        updateVault();
        _distributeUserRewards();
        return users[_msgSender()];
    } 

    /// @notice Internal function to calculate the early withdraw fees.
    /// @notice return feeAmount and withdrawAmount.
    function _calculateFee(uint256 _amount) internal pure returns(uint256 feeAmount, uint256 withdrawAmount) {
        feeAmount = _amount * withdrawFee / 10000;
        withdrawAmount = _amount - feeAmount; 
    }

    /// @notice Calculates and updates the pending rewards of the vault.
    function _pendingVaultRewards() internal {
        uint256 _currentRewards = vault.rewardsPerBlock * (block.number - vault.lastRewardBlock);

        // if remaining rewards are less than currentRewards
        if (vault.remainingRewards <= _currentRewards) {
            // set remainingRewards as currentRewards
            _currentRewards = vault.remainingRewards;
        }
            
        vault.remainingRewards -= _currentRewards;
        vault.pendingRewards += _currentRewards;
        vault.lastRewardBlock = block.number;
    }

    /// @notice Internal function to distribute pending rewards to the user
    function _distributeUserRewards() internal {
        uint256 vaultRewards = vault.pendingRewards;

        uint256 shareOfReward = users[_msgSender()].totUserShares / vault.totalVaultShares * 100;
        uint256 userReward = (vaultRewards * shareOfReward) / 100;
        vault.pendingRewards -=  userReward;

        users[_msgSender()].pendingRewards += userReward;
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
        emit Withdraw(_to, _amount);
        return true;
    }

}