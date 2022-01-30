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
    enum Status { None, Collecting, Started, Completed }
    
    address public admin;

    struct Vault {
        uint256 Id; // ID of the vault.
        IERC20 token; // token in vault.
        Status status; // vault status
        uint256 totalShares; // total tokens deposited into Vault.
        uint256 startBlock;  // block.number when the vault start accouring rewards. 
        uint256 stopBlock; // the block.number to end the staking vault.
        uint256 rewardsPerBlock; // rewards to be realised to the vault ecach block. 
        uint256 lastRewardBlock; // the last block rewards was updated.
        uint256 pendingRewards; // pending rewards for this vault.        
        uint256 remainingRewards; // remaining rewards for this vault.        
        uint256 totalRewards; // amount of tokens to reward this vault.
    }

    struct Pool {
        uint256 totShares;
        uint256 rewardsInPool;
    }

    mapping (uint256 => Vault) public vaultMapping;
    mapping (address => Pool) public poolsMapping;

    error TransferFailed();
    error NotStarted();
    error VaultCompleted();
    error NotEnoughShares();
    
    event VaultInitialized(uint256 indexed id, Status status, uint256 indexed startBlock, uint256 indexed stopBlock);
    event Deposit(uint256 indexed id, uint256 amount);
    event Withdraw(uint256 indexed id, uint256 amount);

    constructor() {
        admin = _msgSender();
    }
    modifier started(uint256 _id) {
        if (vaultMapping[_id].status != Status.Started) revert NotStarted();
        _;
    }

    function initializeVault(IERC20 _token, uint256 _id, uint256 _totVaultRewards) external onlyOwner {
        
        IERC20 token = _token;
        
        vaultMapping[_id] = Vault(
            _id,
            token,
            Status.Collecting,
            0, // totShares
            block.number.add(100),  // starttime
            block.number.add(1000), // stoptime
            4e18, // 4 tokens rewarded Per Block
            block.number.add(100), // lastRewardBlock
            0, // pendingRewards
            _totVaultRewards, // remainingRewards
            _totVaultRewards
        );

        _safeTransferFrom(_id, _msgSender(), address(this), _totVaultRewards);

        emit VaultInitialized(_id, vaultMapping[_id].status, vaultMapping[_id].startBlock, vaultMapping[_id].stopBlock);
    }

    function deposit(uint256 _id, uint256 _amount) external {
        
        if (!_safeTransferFrom(_id , _msgSender(), address(this), _amount)) revert TransferFailed();

        vaultMapping[_id].totalShares += _amount;
        poolsMapping[_msgSender()].totShares += _amount;

        _distributeRewards(_id);

        emit Deposit(_id, _amount);
    }

    function withdraw(uint256 _id, uint256 _amount) external {
        if (_amount > poolsMapping[_msgSender()].totShares) revert NotEnoughShares();

        updateVault(_id);

        uint256 amountToSend = _amount.add(poolsMapping[_msgSender()].rewardsInPool);
        poolsMapping[_msgSender()].rewardsInPool = 0;

        if (!_safeTransfer(_id, _msgSender(), amountToSend)) revert TransferFailed();

        vaultMapping[_id].totalShares -= _amount;
        poolsMapping[_msgSender()].totShares -= _amount;

        emit Withdraw(_id, _amount);
    }

    function _safeTransferFrom(uint256 _id, address _from, address _to, uint256 _amount) private returns (bool) {
        vaultMapping[_id].token.safeTransferFrom(_from, _to, _amount);
        return true;
    }

    function _safeTransfer(uint256 _id, address _to, uint256 _amount) private returns (bool) {
        vaultMapping[_id].token.safeTransfer(_to, _amount);
        return true;
    }
    
    /**
     * @notice Updates the Vaults pending rewards.
     * @param _id The vault to update.
     */
    function updateVault(uint256 _id) public started(_id) {
        if (block.number > vaultMapping[_id].stopBlock) revert VaultCompleted();
        (uint256 currentBlock, uint256 pendingRewards) = _pendingRewards(_id);

        if (currentBlock == vaultMapping[_id].stopBlock) {
            vaultMapping[_id].status = Status.Completed;
        } 

        vaultMapping[_id].lastRewardBlock = currentBlock;
        vaultMapping[_id].pendingRewards += pendingRewards;
        vaultMapping[_id].remainingRewards -= pendingRewards;

        _distributeRewards(_id);
        
    }

    function _pendingRewards(uint256 _id) private view returns (uint256 currentBlock, uint256 pendingRewards) {
        currentBlock = block.number; 
        uint256 _rewardPeriod = currentBlock.sub(vaultMapping[_id].lastRewardBlock);
        pendingRewards = vaultMapping[_id].rewardsPerBlock.add(_rewardPeriod);
    }

    function _distributeRewards(uint256 _id) private {
        uint256 rewards = vaultMapping[_id].pendingRewards;
        vaultMapping[_id].pendingRewards = 0;

        uint256 shareOfReward = poolsMapping[_msgSender()].totShares.div(vaultMapping[_id].totalShares).mul(100);
        poolsMapping[_msgSender()].rewardsInPool += rewards.mul(shareOfReward).div(100);
    }

    /**
    * @notice A setter function to set the status.
    */
    function startVault(uint256 _id) external onlyOwner {
        vaultMapping[_id].status = Status.Started;
        vaultMapping[_id].startBlock = block.number;
        vaultMapping[_id].lastRewardBlock = block.number;

    }
}