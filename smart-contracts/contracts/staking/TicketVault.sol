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
    mapping (address => User) public usersMapping;

    error FailedInitVault();
    error DepositFailed();
    error WithdrawFailed();
    error WithdrawFeeFailed();
    error NotStarted();
    error NotCollecting();
    error VaultCompleted();
    error NotEnoughShares();
    error NotAuthorized();
    error AlreadyInitialized();
    
    event VaultInitialized(IERC20 token, uint256 rewardsPerBlock, uint256 totalVaultRewards);
    event Deposit(uint256 amount, address user);
    event Withdraw(uint256 amount, address user);
    event EarlyWithdraw(uint256 amount, address user);
    event Rewards(address indexed reciever, uint256 amount);
    event ValutCompleted(IERC20 token, uint256 totalVaultRewards, uint256 remainingRewards);

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
        if (_msgSender() != usersMapping[_msgSender()].user) revert NotAuthorized();
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

    function initializeVault(uint256 _rewardsPerBlock, uint256 _totVaultRewards)
        external 
        onlyOwner
        notInitialized()
    {
        vault.status = Status.Collecting;
        // ethereum mainnet averages 6500 blocksPerDay.
        // 3360000000000000000 _rewardPerBlock.
        vault.rewardsPerBlock = _rewardsPerBlock;

        vault.lastRewardBlock =  block.number;
        vault.remainingRewards =  _totVaultRewards;
        vault.totalVaultRewards =  _totVaultRewards;

        if(!_deposit(_msgSender(), _totVaultRewards)) revert FailedInitVault();
        initialized;
        emit VaultInitialized(token, vault.rewardsPerBlock, vault.totalVaultRewards);
    }

    function deposit(uint256 _amount) external returns (bool) {

        if (!_safeTransferFrom(_msgSender(), address(this), _amount)) revert DepositFailed();

        vault.totalVaultShares += _amount;

        usersMapping[_msgSender()].user = address(_msgSender());
        usersMapping[_msgSender()].totUserShares += _amount;
        usersMapping[_msgSender()].lastDepositedTime = block.timestamp;

        emit Deposit(_amount, _msgSender());
        return true;
    }

    function withdraw(uint256 _amount) external isUser() returns (bool) {
        if (_amount >= usersMapping[_msgSender()].totUserShares) revert NotEnoughShares();

        if (vault.status == Status.Collecting) {
            require(_safeTransfer(_msgSender(), _amount), "withdraw failed");
            return true;
        } 

        updateVault();
        _distributeUserRewards();

        if (block.timestamp <= usersMapping[_msgSender()].lastDepositedTime.add(vault.withdrawPenaltyPeriod)) {
            require(_safeTransfer(feeAddress, usersMapping[_msgSender()].pendingRewards), "failed Withdraw");
            require(_safeTransfer(_msgSender(), _amount));

            usersMapping[_msgSender()].pendingRewards = 0;
            vault.totalVaultShares -= _amount;
            usersMapping[_msgSender()].totUserShares -= _amount;

            emit EarlyWithdraw(_amount, _msgSender());

            return true;
        }
        
        uint256 amountToSend = _amount.add(usersMapping[_msgSender()].pendingRewards);
        
        usersMapping[_msgSender()].pendingRewards = 0;
        vault.totalVaultShares -= _amount;
        usersMapping[_msgSender()].totUserShares -= _amount;

        // if after penalty period, and within withdrawfee period.
        if (
            block.timestamp > usersMapping[_msgSender()].lastDepositedTime + vault.withdrawPenaltyPeriod && 
            block.timestamp < usersMapping[_msgSender()].lastDepositedTime + vault.withdrawFeePeriod
        ) {
            uint256 currentWithdrawFee = (amountToSend * withdrawFee) / 1000;
            if (!_withdraw(feeAddress, currentWithdrawFee)) revert WithdrawFeeFailed();
            
            amountToSend = amountToSend.sub(currentWithdrawFee);
        }
        
        
        emit Withdraw(amountToSend, _msgSender());

        return true;
    }

    function _deposit(address _from, uint256 _amount) internal returns (bool) {
        if(!_safeTransferFrom(address(_from), address(this), _amount)) revert DepositFailed();
        return true;
    }

    function _withdraw(address _to, uint256 _amount) internal returns (bool) {
        if(!_safeTransfer(_to, _amount)) revert WithdrawFailed();
        return true;
    }

    function _safeTransferFrom(address _from, address _to, uint256 _amount) private returns (bool) {
        token.safeTransferFrom(_from, _to, _amount);
        return true;
    }

    function _safeTransfer(address _to, uint256 _amount) private returns (bool) {
        token.safeTransfer(_to, _amount);
        return true;
    }
    
    /**
     * @notice Updates the Vaults pending rewards.
     */
    function updateVault() public {
        if (block.number > vault.stopBlock) revert VaultCompleted();
        if (vault.remainingRewards <= 0) revert VaultCompleted();

        (uint256 currentBlock, uint256 pendingRewards) = _pendingRewards();

        if (currentBlock == vault.stopBlock) {
            vault.status = Status.Completed;
            emit ValutCompleted(token, vault.totalVaultRewards, vault.remainingRewards);
        } 

        vault.lastRewardBlock = currentBlock;
        vault.pendingRewards += pendingRewards;
        vault.remainingRewards -= pendingRewards;
        
    }

    function _pendingRewards() private view returns (uint256 currentBlock, uint256 pendingRewards) {
        currentBlock = block.number; 
        uint256 _rewardPeriod = currentBlock.sub(vault.lastRewardBlock);
        pendingRewards = vault.rewardsPerBlock.mul(_rewardPeriod);
    }

    function _distributeUserRewards() private {
        uint256 rewards = vault.pendingRewards;

        uint256 shareOfReward = usersMapping[_msgSender()].totUserShares.div(vault.totalVaultShares).mul(100);
        uint256 userReward = rewards.mul(shareOfReward).div(100);

        usersMapping[_msgSender()].pendingRewards += userReward;
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
        amount = usersMapping[_msgSender()].pendingRewards;
        usersMapping[_msgSender()].pendingRewards = 0;

        require(_safeTransfer(_msgSender(), amount));

        emit Rewards(_msgSender(), amount);
    }

}// SPDX-License-Identifier: MIT
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
    mapping (address => User) public usersMapping;

    error FailedInitVault();
    error DepositFailed();
    error WithdrawFailed();
    error WithdrawFeeFailed();
    error NotStarted();
    error NotCollecting();
    error VaultCompleted();
    error NotEnoughShares();
    error NotAuthorized();
    error AlreadyInitialized();
    
    event VaultInitialized(IERC20 token, uint256 rewardsPerBlock, uint256 totalVaultRewards);
    event Deposit(uint256 amount, address user);
    event Withdraw(uint256 amount, address user);
    event EarlyWithdraw(uint256 amount, address user);
    event Rewards(address indexed reciever, uint256 amount);
    event ValutCompleted(IERC20 token, uint256 totalVaultRewards, uint256 remainingRewards);

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
        if (_msgSender() != usersMapping[_msgSender()].user) revert NotAuthorized();
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

    function initializeVault(uint256 _rewardsPerBlock, uint256 _totVaultRewards)
        external 
        onlyOwner
        notInitialized()
    {
        vault.status = Status.Collecting;
        // ethereum mainnet averages 6500 blocksPerDay.
        // 3360000000000000000 _rewardPerBlock.
        vault.rewardsPerBlock = _rewardsPerBlock;

        vault.lastRewardBlock =  block.number;
        vault.remainingRewards =  _totVaultRewards;
        vault.totalVaultRewards =  _totVaultRewards;

        if(!_deposit(_msgSender(), _totVaultRewards)) revert FailedInitVault();
        initialized;
        emit VaultInitialized(token, vault.rewardsPerBlock, vault.totalVaultRewards);
    }

    function deposit(uint256 _amount) external returns (bool) {

        if (!_safeTransferFrom(_msgSender(), address(this), _amount)) revert DepositFailed();

        vault.totalVaultShares += _amount;

        usersMapping[_msgSender()].user = address(_msgSender());
        usersMapping[_msgSender()].totUserShares += _amount;
        usersMapping[_msgSender()].lastDepositedTime = block.timestamp;

        emit Deposit(_amount, _msgSender());
        return true;
    }

    function withdraw(uint256 _amount) external isUser() returns (bool) {
        if (_amount >= usersMapping[_msgSender()].totUserShares) revert NotEnoughShares();

        if (vault.status == Status.Collecting) {
            require(_safeTransfer(_msgSender(), _amount), "withdraw failed");
            return true;
        } 

        updateVault();
        _distributeUserRewards();

        if (block.timestamp <= usersMapping[_msgSender()].lastDepositedTime.add(vault.withdrawPenaltyPeriod)) {
            require(_safeTransfer(feeAddress, usersMapping[_msgSender()].pendingRewards), "failed Withdraw");
            require(_safeTransfer(_msgSender(), _amount));

            usersMapping[_msgSender()].pendingRewards = 0;
            vault.totalVaultShares -= _amount;
            usersMapping[_msgSender()].totUserShares -= _amount;

            emit EarlyWithdraw(_amount, _msgSender());

            return true;
        }
        
        uint256 amountToSend = _amount.add(usersMapping[_msgSender()].pendingRewards);
        
        usersMapping[_msgSender()].pendingRewards = 0;
        vault.totalVaultShares -= _amount;
        usersMapping[_msgSender()].totUserShares -= _amount;

        // if after penalty period, and within withdrawfee period.
        if (
            block.timestamp > usersMapping[_msgSender()].lastDepositedTime + vault.withdrawPenaltyPeriod && 
            block.timestamp < usersMapping[_msgSender()].lastDepositedTime + vault.withdrawFeePeriod
        ) {
            uint256 currentWithdrawFee = (amountToSend * withdrawFee) / 1000;
            if (!_withdraw(feeAddress, currentWithdrawFee)) revert WithdrawFeeFailed();
            
            amountToSend = amountToSend.sub(currentWithdrawFee);
        }
        
        
        emit Withdraw(amountToSend, _msgSender());

        return true;
    }

    function _deposit(address _from, uint256 _amount) internal returns (bool) {
        if(!_safeTransferFrom(address(_from), address(this), _amount)) revert DepositFailed();
        return true;
    }

    function _withdraw(address _to, uint256 _amount) internal returns (bool) {
        if(!_safeTransfer(_to, _amount)) revert WithdrawFailed();
        return true;
    }

    function _safeTransferFrom(address _from, address _to, uint256 _amount) private returns (bool) {
        token.safeTransferFrom(_from, _to, _amount);
        return true;
    }

    function _safeTransfer(address _to, uint256 _amount) private returns (bool) {
        token.safeTransfer(_to, _amount);
        return true;
    }
    
    /**
     * @notice Updates the Vaults pending rewards.
     */
    function updateVault() public {
        if (block.number > vault.stopBlock) revert VaultCompleted();
        if (vault.remainingRewards <= 0) revert VaultCompleted();

        (uint256 currentBlock, uint256 pendingRewards) = _pendingRewards();

        if (currentBlock == vault.stopBlock) {
            vault.status = Status.Completed;
            emit ValutCompleted(token, vault.totalVaultRewards, vault.remainingRewards);
        } 

        vault.lastRewardBlock = currentBlock;
        vault.pendingRewards += pendingRewards;
        vault.remainingRewards -= pendingRewards;
        
    }

    function _pendingRewards() private view returns (uint256 currentBlock, uint256 pendingRewards) {
        currentBlock = block.number; 
        uint256 _rewardPeriod = currentBlock.sub(vault.lastRewardBlock);
        pendingRewards = vault.rewardsPerBlock.mul(_rewardPeriod);
    }

    function _distributeUserRewards() private {
        uint256 rewards = vault.pendingRewards;

        uint256 shareOfReward = usersMapping[_msgSender()].totUserShares.div(vault.totalVaultShares).mul(100);
        uint256 userReward = rewards.mul(shareOfReward).div(100);

        usersMapping[_msgSender()].pendingRewards += userReward;
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
        amount = usersMapping[_msgSender()].pendingRewards;
        usersMapping[_msgSender()].pendingRewards = 0;

        require(_safeTransfer(_msgSender(), amount));

        emit Rewards(_msgSender(), amount);
    }

}