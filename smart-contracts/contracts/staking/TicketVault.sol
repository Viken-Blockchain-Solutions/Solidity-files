// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* notes: ETH mainnet averages 6500 BPD.
*        2 000 000 total reward for three months Vault.
*        Three months = 91.310625 days.
*        2 000 000 CENT / 91.310625 days = 21903.256055908061083 CENT per day.
*        21903.256055908061083 CENT per day / 6500 Blocks per day = 3.369731700908932.
*        2m cent divided on three months is 3.36 cent per block (3360000000000000000 wei)
*/
contract TicketVault is Context, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice enum Status contains multiple status.
     * The different "statuses" are represented as index numbers.
     */
    enum Status { Collecting, Started, Completed }
    
    IERC20 public token;
    address public admin;
    address public feeAddress;
    uint256 public withdrawFee = 700; // 7%
    bool public initialized;

    struct Vault {
        Status status; // vault status
        uint256 totalVaultShares; // total tokens deposited into Vault.
        uint256 startBlock;  // block.number when the vault start accouring rewards. 
        uint256 stopBlock; // the block.number to end the staking vault.
        uint256 rewardsPerBlock; // rewards to be realised to the vault ecach block. 
        uint256 lastRewardBlock; // the last block rewards was updated.
        uint256 pendingRewards; // pending rewards for this vault.        
        uint256 remainingRewards; // remaining rewards for this vault.        
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
        uint256 withdrawFeePeriod; // 12 weeks;
        uint256 withdrawPenaltyPeriod; // 14 days;
    }

    struct User {
        address user;
        uint256 totUserShares;
        uint256 lastDepositedTime;
        uint256 pendingRewards;
    }

    Vault public vault;
    mapping (address => User) public users;

    error FailedToInitVault();
    error AlreadyInitialized();
    error NotAuthorized();
    error NotEnoughShares();

    error DepositFailed();
    error WithdrawFailed();
    error CalculateFeesFailed();
    error WithdrawFeesFailed();
   
    error NotStarted();
    error NotCollecting();
    error VaultCompleted();
    error RewardsCompleted();
   
    
    event VaultInitialized();
    event Deposit(uint256 amount, address indexed user);
    event Withdraw(uint256 amount, address indexed user);
    event EarlyWithdraw(uint256 amount, address indexed user);
    event Rewards(uint256 amount, address indexed reciever);
    event ValutCompleted(uint256 totalVaultRewards, uint256 remainingRewards);

    constructor(IERC20 _token, address _admin, address _feeAddress) {
        token = _token;
        admin = _admin;
        feeAddress = _feeAddress;
    }
    
    modifier notInitialized() {
        if (initialized) 
            revert AlreadyInitialized();
        _;
        initialized = true;
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
    // 3360000000000000000 _rewardPerBlock.
    function initializeVault(uint256 rewardsPerBlock, uint256 totVaultRewards)
        external 
        onlyOwner
        notInitialized()
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

    function deposit(uint256 _amount) external returns (bool) {
        if (!_deposit(_msgSender(), _amount)) revert DepositFailed();

        vault.totalVaultShares += _amount;
        users[_msgSender()].user = address(_msgSender());
        users[_msgSender()].totUserShares += _amount;
        users[_msgSender()].lastDepositedTime = block.timestamp;

        emit Deposit(_amount, _msgSender());
        return true;
    }

    function withdraw(uint256 _amount) external isUser() returns (bool) {
        if (users[_msgSender()].totUserShares < _amount) revert NotEnoughShares();

        uint256 _shares = _amount;
        users[_msgSender()].totUserShares -= _shares;
        vault.totalVaultShares -= _shares;

        // if Vault status is collecting. 
        // Pay 7% withdrawFee before withdraw, No rewards!
        if (vault.status == Status.Collecting) {

            (uint256 _feeAmount, uint256 _withdrawAmount) = _calculateFee(_shares);
            
            require(_withdraw(feeAddress, _feeAmount));
            require(_withdraw(_msgSender(), _withdrawAmount));
            
            return true;
        } 

        // if Vault status is started (ongoing).
        // Pay 7% withdraw fee from stake and reward before withdraw.
        if (vault.status == Status.Started) {
            _distributeUserRewards;

            uint256 _userRewards = users[_msgSender()].pendingRewards;
            users[_msgSender()].pendingRewards = 0;

            (uint256 feeAmount, uint256 withdrawAmount) = _calculateFee(_shares + _userRewards);
            
            require(_withdraw(feeAddress, feeAmount));
            require(_withdraw(_msgSender(), withdrawAmount));

            emit EarlyWithdraw(_amount, _msgSender());

            return true;
        }
        
        // if Vault status is completed (finished).
        // Withdraw stake and rewards without extra fees.
        if (vault.status == Status.Completed) {
            uint256 _userRewards = users[_msgSender()].pendingRewards;
            users[_msgSender()].pendingRewards = 0;
            
            uint256 withdrawAmount = _shares + _userRewards;
            require(_withdraw(_msgSender(), withdrawAmount));

            return true;
        }

        else {
            revert WithdrawFailed();
        }
    }

    function _deposit(address _from, uint256 _amount) internal returns (bool) {
        if(!_safeTransferFrom(address(_from), address(this), _amount)) revert DepositFailed();

        emit Deposit(_amount, _from);
        return true;
    }

    function _withdraw(address _to, uint256 _amount) internal returns (bool) {
        if(!_safeTransfer(address(_to), _amount)) revert WithdrawFailed();

        emit Withdraw(_amount, _to);
        return true;
    }

    function _calculateFee(uint256 _amount) internal view returns(uint256 feeAmount, uint256 withdrawAmount) {
        feeAmount = _amount * withdrawFee / 1000;
        withdrawAmount = _amount - feeAmount; 
    }

    function _safeTransfer(address _to, uint256 _amount) private returns (bool) {
        token.safeTransfer(_to, _amount);
        return true;
    }

    function _safeTransferFrom(address _from, address _to, uint256 _amount) private returns (bool) {
        token.safeTransferFrom(_from, _to, _amount);
        return true;
    }
    
    /**
     * @notice Updates the Vaults pending rewards.
     */
    function updateVault() public {
        if (vault.status == Status.Completed) revert VaultCompleted();
        if (vault.remainingRewards <= 0) revert RewardsCompleted();

        _pendingRewards();

        if (block.number == vault.stopBlock) {
            vault.status = Status.Completed;
            emit ValutCompleted(vault.totalVaultRewards, vault.remainingRewards);
        } 

    
        
    }

    // calculates and updates the pending rewards of the vault.
    function _pendingRewards() internal {
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

    function _distributeUserRewards() private {
        uint256 vaultRewards = vault.pendingRewards;

        uint256 shareOfReward = users[_msgSender()].totUserShares / vault.totalVaultShares * 100;
        uint256 userReward = vaultRewards.mul(shareOfReward).div(100);

        users[_msgSender()].pendingRewards += userReward;
        vault.pendingRewards -=  userReward;
    }

    /**
     * @notice A setter function to set the status.
     */
    function startVault(uint256 _stopBlock) external onlyOwner {
        vault.status = Status.Started;
        vault.startBlock = block.number;
        vault.stopBlock = _stopBlock;
        vault.lastRewardBlock = block.number;
        vault.withdrawFeePeriod = 12 weeks; // fee period 
        vault.withdrawPenaltyPeriod = 14 days; // penalty period

    }

    /**
     * @notice A setter function to set the status.
     */
    function startCollecting() external onlyOwner {
        vault.status = Status.Collecting;
    }

    /**
     * @notice A setter function to set the status.
     */
    function stopVault() external onlyOwner {
        vault.status = Status.Completed;
        vault.stopBlock = block.number;
    }

    function claim() external isUser() isStarted() returns (uint256 amount){
        updateVault();
        _distributeUserRewards();
        amount = users[_msgSender()].pendingRewards;
        users[_msgSender()].pendingRewards = 0;

        require(_safeTransfer(_msgSender(), amount));

        emit Rewards(amount, _msgSender());
    }

}