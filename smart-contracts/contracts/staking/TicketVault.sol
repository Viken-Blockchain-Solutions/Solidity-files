// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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



    struct Vault {
        IERC20 token; // token in vault.
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
    error NotStarted();
    error NotCollecting();
    error VaultCompleted();
    error NotEnoughShares();
    error NotAuthorized();
    
    event VaultInitialized();
    event Deposit(uint256 amount, address user);
    event Withdraw(uint256 amount, address user);
    event EarlyWithdraw(uint256 amount, address user);
    event Rewards(address indexed reciever, uint256 amount);
    event ValutCompleted(IERC20 token, uint256 rewardsPerBlock, uint256 totalVaultRewards);

    constructor(address _admin, address _feeAddress) {
        admin = _admin;
        feeAddress = _feeAddress;
    }

    modifier isUser(uint256 _id) {
        if (_msgSender() != usersMapping[_id][_msgSender()].user) revert NotAuthorized();
        _;
    }

    modifier isStarted(uint256 _id) {
        if (vaultMapping[_id].status != Status.Started) revert NotStarted();
        _;
    }

    modifier isCollecting(uint256 _id) {
        if (vaultMapping[_id].status != Status.Collecting) revert NotCollecting();
        _;
    }

    function initializeVault(IERC20 _token, uint256 _rewardsPerBlock, uint256 _totVaultRewards) external onlyOwner {
        Vault.token = _token;
        Vault.status = Status.Collecting;
        Vault.rewardsPerBlock = _rewardsPerBlock;
        Vault.lastRewardBlock =  block.number;
        Vault.remainingRewards =  _totVaultRewards;
        Vault.totalVaultRewards =  _totVaultRewards;

        if(!_safeTransferFrom(_msgSender(), address(this), _totVaultRewards)) revert FailedInitVault();

        emit VaultInitialized(Vault.token, Vault.rewardsPerBlock, Vault.totalVaultRewards);
    }

    function deposit(uint256 _amount) external isCollecting(_id) returns (bool) {

        if (!_safeTransferFrom(_id , _msgSender(), address(this), _amount)) revert DepositFailed();

        vaultMapping[_id].totalVaultShares += _amount;

        usersMapping[_id][_msgSender()].user = address(_msgSender());
        usersMapping[_id][_msgSender()].totUserShares += _amount;
        usersMapping[_id][_msgSender()].lastDepositedTime = block.number;

        emit Deposit(_id, _amount, _msgSender());
        return true;
    }

    function withdraw(uint256 _amount) external isUser(_id) returns (bool) {
        if (_amount >= usersMapping[_id][_msgSender()].totUserShares) revert NotEnoughShares();

        if (vaultMapping[_id].status == Status.Collecting) {
            require(_safeTransfer(_id, _msgSender(), _amount), "withdraw failed");
            return true;
        } 

        updateVault(_id);
        _distributeUserRewards(_id);

        if (block.timestamp <= usersMapping[_id][_msgSender()].lastDepositedTime.add(vaultMapping[_id].withdrawPenaltyPeriod)) {
            require(_safeTransfer(_id, feeAddress, usersMapping[_id][_msgSender()].pendingRewards), "failed Withdraw");
            require(_safeTransfer(_id, _msgSender(), _amount));

            usersMapping[_id][_msgSender()].pendingRewards = 0;
            vaultMapping[_id].totalVaultShares -= _amount;
            usersMapping[_id][_msgSender()].totUserShares -= _amount;

            emit EarlyWithdraw(_id, _amount, _msgSender());

            return true;
        }
        
        uint256 amountToSend = _amount.add(usersMapping[_id][_msgSender()].pendingRewards);
        
        usersMapping[_id][_msgSender()].pendingRewards = 0;
        vaultMapping[_id].totalVaultShares -= _amount;
        usersMapping[_id][_msgSender()].totUserShares -= _amount;

        // if after penalty period, and before withdrawfee period.
        if (
            block.timestamp >= usersMapping[_id][_msgSender()].lastDepositedTime.add(vaultMapping[_id].withdrawPenaltyPeriod) && 
            block.timestamp < usersMapping[_id][_msgSender()].lastDepositedTime.add(vaultMapping[_id].withdrawFeePeriod)
        ) {
            uint256 currentWithdrawFee = amountToSend.mul(withdrawFee).div(1000);
            require(_safeTransfer(_id, feeAddress, currentWithdrawFee), "fee transaction failed");
            
            amountToSend = amountToSend.sub(currentWithdrawFee);
        }
        
        if (!_safeTransfer(_id, _msgSender(), amountToSend)) revert TransferFailed();
        
        emit Withdraw(_id, amountToSend, _msgSender());

        return true;
    }

    function _withdraw(address _to, uint256 _amount) internal returns (bool) {
        if(!_safeTransfer(_id, _to, _amount) revert WithdrawFailed();
    }

    function _safeTransferFrom(address _from, address _to, uint256 _amount) private returns (bool) {
        vaultMapping[_id].token.safeTransferFrom(_from, _to, _amount);
        return true;
    }

    function _safeTransfer(address _to, uint256 _amount) private returns (bool) {
        vaultMapping[_id].token.safeTransfer(_to, _amount);
        return true;
    }
    
    /**
     * @notice Updates the Vaults pending rewards.
     * @param _id The vault to update.
     */
    function updateVault() public {
        if (block.number > vaultMapping[_id].stopBlock) revert VaultCompleted();
        if (vaultMapping[_id].remainingRewards <= 0) revert VaultCompleted();

        (uint256 currentBlock, uint256 pendingRewards) = _pendingRewards(_id);

        if (currentBlock == vaultMapping[_id].stopBlock) {
            vaultMapping[_id].status = Status.Completed;
            emit ValutCompleted(_id);
        } 

        vaultMapping[_id].lastRewardBlock = currentBlock;
        vaultMapping[_id].pendingRewards += pendingRewards;
        vaultMapping[_id].remainingRewards -= pendingRewards;
        
    }

    function _pendingRewards(uint256 _id) private view returns (uint256 currentBlock, uint256 pendingRewards) {
        currentBlock = block.number; 
        uint256 _rewardPeriod = currentBlock.sub(vaultMapping[_id].lastRewardBlock);
        pendingRewards = vaultMapping[_id].rewardsPerBlock.mul(_rewardPeriod);
    }

    function _distributeUserRewards(uint256 _id) private {
        uint256 rewards = vaultMapping[_id].pendingRewards;

        uint256 shareOfReward = usersMapping[_id][_msgSender()].totUserShares.div(vaultMapping[_id].totalVaultShares).mul(100);
        uint256 userReward = rewards.mul(shareOfReward).div(100);

        usersMapping[_id][_msgSender()].pendingRewards += userReward;
        vaultMapping[_id].pendingRewards -=  userReward;
    }

    /**
     * @notice A setter function to set the status.
     */
    function startVault(uint256 _id, uint256 _stopBlock) external onlyOwner {
        vaultMapping[_id].status = Status.Started;
        vaultMapping[_id].startBlock = block.number;
        vaultMapping[_id].stopBlock = _stopBlock;
        vaultMapping[_id].lastRewardBlock = block.number;
        vaultMapping[_id].withdrawFeePeriod = 12 weeks; // fee period 
        vaultMapping[_id].withdrawPenaltyPeriod = 14 days; // penalty period

    }

    /**
     * @notice A setter function to set the status.
     */
    function startCollecting(uint256 _id) external onlyOwner {
        vaultMapping[_id].status = Status.Collecting;
    }

    /**
     * @notice A setter function to set the status.
     */
    function stopVault(uint256 _id) external onlyOwner {
        vaultMapping[_id].status = Status.Completed;
        vaultMapping[_id].stopBlock = block.number;
    }

    function claim(uint256 _id) external isUser(_id) isStarted(_id) returns (uint256 amount){
        updateVault(_id);
        _distributeUserRewards(_id);
        amount = usersMapping[_id][_msgSender()].pendingRewards;
        usersMapping[_id][_msgSender()].pendingRewards = 0;

        require(_safeTransfer(_id, _msgSender(), amount));

        emit Rewards(_id, _msgSender(), amount);
    }

}