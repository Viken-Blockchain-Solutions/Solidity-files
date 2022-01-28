// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
*   Advanced-logic: Pending Reward logic.
*   The formula we use to calculate the pending reward of each user:
*   - Pending Reward = (user.amount * pool.accCENTPerShare) - user.rewardDebt
*
*   Everytime a user deposits or withdraws to the single-token pool. This happens:
*   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
*   2. User receives the pending reward sent to his/her address.
*   3. User's `amount` gets updated.
*   4. User's `rewardDebt` gets updated.
*/

contract TicketMaster is Context, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Struct with the staking data of each user.
     * @param totalShares The amount of CENT a user is staking.
     * @param lastUserInteraction Block.timestamp of the last user interaction.
     * @param sharesAtLastUserInteraction Total amount of shares the user had at their last interaction.
     */
    struct UserInfo {
        uint256 userShares;
        uint256 lastDeposit;    
        uint256 sharesAtLastInteraction;
        uint256 lastUserInteraction;
    }
        
    /**
     * @notice PoolInfo Struct with the staking data of the pool.
     * @param erc20 Address of the staking token.
     * @param allocPoint The amount of allocation points assigned to this pool.
     * @param lastRewardBlock Last block number that CENT distribution occures.
     * @param accTokenPerShare Accumulated Tokens per share, times 1e12.
     */
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 totCentStakedInPool;
    }
    
    IERC20 public immutable token; // Staking token

    bool public initialized;
    
    address public feeAddress;
    
    uint256 public sharesPerBlock;
    uint256 public startBlock;
    uint256 public bonus_multiplier = 0;
    PoolInfo public poolInfo;

    mapping (address => UserInfo) public userInfo;

    error NotAuthorized();
    error OnlyOnce();
    error TransferFailed();
    

    modifier onlyDev() {
        if (_msgSender() != dev) {
            revert NotAuthorized();
        }
        _;
    }

    modifier notInitialized(){
        if (initialized) revert OnlyOnce();
        _;
        initialized = true;
    }

    event StakedToPool(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 centPerBlock);
    event PoolInitialized(uint256 _allocPoint, IERC20 _lpToken, uint256 _totRewardAmount);
    event SentPendingRewards(address indexed user, uint256 amount);

    /**
     * @param _dev Dev address.
     * @param _centPerBlock The amount of tokens to reward each block number.
     */ 
    constructor(address _dev, uint256 _centPerBlock) {
        dev = _dev;
        centPerBlock = _centPerBlock;
        startBlock = block.number;
    }

    /**
     * @notice receive (fallback function) If Ether is sendt to this contract,
     *         the transaction reverts and returns the funds to the sender.
     */ 
    receive() external payable {
        revert("not payable receive");
    }

    /**
     * @notice Update to a new dev address by the previous dev address.
     * @param _dev New dev address.
     * @dev  protected by modifier dev.
     */
    function setDevAddress(address _dev) external onlyDev {
        dev = _dev;
    }

    /**
     * @notice Initiates a new pool. Can only be called by the owner.
     * @param _allocPoint Amount of CENT being allocated to this pool.
     * @param _lpToken Reward token address.
     * @param _totRewardAmount Amount of tokens to be allocated as Reward.
     * @dev This is executed in order:
     * @dev 1. sets the current block.number as lastRewardBlock.
     * @dev 2. adds the _allocPoint to totalAllocPoint.
     * @dev 3. creates an entry as true for the pool in poolExistence[].
     * @dev 4. adds the values to the pool.
     * @dev 5. executes a transfer of rewardtokens, into this smartcontract.
     */ 
    function initiatePool(uint256 _allocPoint, IERC20 _lpToken, uint256 _totRewardAmount) 
        external
        onlyOwner
        notInitialized
    {
        IERC20 lpToken = _lpToken;
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        
        poolInfo.lpToken = lpToken;
        poolInfo.allocPoint = _allocPoint;
        poolInfo.lastRewardBlock = lastRewardBlock;
        poolInfo.accTokenPerShare = 0;
        poolInfo.totCentStakedInPool = 0;

        _transferFrom(address(_msgSender()), address(this), _totRewardAmount);
        initialized = true;
        emit PoolInitialized(_allocPoint, _lpToken, _totRewardAmount);
    }

    /**
     * @notice Update the pool'd CENT allocation amount.
     * @param _newAllocPoint New amount to allocate to the pool. Will replace existing allocation.
     * @dev  Can only be called by the owner.
     */ 
    function updateAllocation(uint256 _newAllocPoint) external onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo.allocPoint).add(_newAllocPoint);
        poolInfo.allocPoint = _newAllocPoint;
    }

    /**
     * @notice Update data variables of the given pool to be up-to-date.
     */
    function updatePool() public {
        // check if pool has started rewarding.
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = poolInfo.lpToken.balanceOf(address(this));

        if (lpSupply == 0 || poolInfo.allocPoint == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, block.number);
        uint256 centReward = 
            multiplier.mul(centPerBlock).mul(poolInfo.allocPoint).div(totalAllocPoint);
        
        if (!_transfer(address(dev), centReward.div(10))) {
            revert TransferFailed();
        }

        poolInfo.accTokenPerShare = poolInfo.accTokenPerShare.add(centReward.mul(1e12).div(lpSupply));
        poolInfo.lastRewardBlock = block.number;
    }

    /**
     * @notice View function to see pending Cent´s on frontend.
     * @param _user The User to retrieve the pending info.
     */
    function pendingCent(address _user) external view returns (uint256) {
        uint256 accTokenPerShare = poolInfo.accTokenPerShare;
        uint256 lpSupply = poolInfo.lpToken.balanceOf(address(this));
        
        if (block.number > poolInfo.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, block.number);
            uint256 centReward = multiplier.mul(centPerBlock).mul(poolInfo.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(centReward.mul(1e12).div(lpSupply));
        }
        return userInfo[_user].amount.mul(accTokenPerShare).div(1e12).sub(userInfo[_user].rewardDebt);
    }

    /**
     * @notice Set startBlock.
     * @param _startBlock New block.number for startBlock.
     */ 
    function setStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;
    }

    /**
     * @notice Update the emission rate of pool.
     * @param _centPerBlock new amount to reward per block.
     * @dev  protected by modifier onlyOwner.
     */
    function updateEmissionRate(uint256 _centPerBlock) external onlyOwner {
        updatePool();
        centPerBlock = _centPerBlock;
        
        emit UpdateEmissionRate(_msgSender(), centPerBlock);
    }

    /** 
     * @notice Stake CENT to earn rewards.
     * @param _amount amount of CENT tokens to stake.
     */
    function addStake(uint256 _amount) public nonReentrant {
        updatePool();
        
        if (userInfo[_msgSender()].amount > 0) {
            uint256 pending = userInfo[_msgSender()].amount
                .mul(poolInfo.accTokenPerShare)
                    .div(1e12)
                        .sub(userInfo[_msgSender()].rewardDebt);

            if (pending > 0) {
                _transfer(address(_msgSender()), pending);
            }
        }
        if (_amount > 0) {
            userInfo[_msgSender()].amount = userInfo[_msgSender()].amount.add(_amount);
            _transferFrom(address(_msgSender()), address(this), _amount);
        }

        userInfo[_msgSender()].rewardDebt = userInfo[_msgSender()].amount.mul(poolInfo.accTokenPerShare).div(1e12);
        poolInfo.totCentStakedInPool = poolInfo.totCentStakedInPool.add(_amount);
        emit StakedToPool(_msgSender(), _amount);
    }

    /**
     * @notice Withdraw staked tokens from Staking contract.
     * @param _amount The staked amount to withdraw.
     */
    function withdrawStake(uint256 _amount) public nonReentrant {
        require(_msgSender() != address(0), "Zero Address!");
        require(userInfo[_msgSender()].amount >= _amount);
        updatePool();
        
        uint256 pending = userInfo[_msgSender()].amount.mul(poolInfo.accTokenPerShare).div(1e12).sub(userInfo[_msgSender()].rewardDebt);

        // transfer pending reward.
        if (pending > 0) {
            uint256 _pending = pending;
            pending = 0;
            require(_transfer(address(_msgSender()), _pending));
            emit SentPendingRewards(_msgSender(), _pending);
        }
        
        // transfer staked amount.
        if (_amount > 0) {
            userInfo[_msgSender()].amount = userInfo[_msgSender()].amount.sub(_amount);
            if (!_transfer(address(_msgSender()), _amount)) revert TransferFailed();
        }
        userInfo[_msgSender()].rewardDebt = userInfo[_msgSender()].amount.mul(poolInfo.accTokenPerShare).div(1e12);
        poolInfo.totCentStakedInPool = poolInfo.totCentStakedInPool.sub(_amount);
        emit Withdraw(_msgSender(), _amount);
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     */
    function emergencyWithdraw() public nonReentrant {
        require(_msgSender() != address(0), "Zero Address!");

        uint256 _amount = userInfo[_msgSender()].amount;
        userInfo[_msgSender()].amount = 0;
        userInfo[_msgSender()].rewardDebt = 0;

        _transfer(address(_msgSender()), _amount);

        assert(userInfo[_msgSender()].amount == 0 && userInfo[_msgSender()].rewardDebt == 0);
        poolInfo.totCentStakedInPool = poolInfo.totCentStakedInPool.sub(_amount);
        emit EmergencyWithdraw(_msgSender(), _amount);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) internal pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    /**
     * @notice Secure internal _transferFrom.
     * @param _from The address from.
     * @param _to The address to.
     * @param _amount The transfer amount.
     */
    function _transferFrom(address _from, address _to, uint256 _amount) 
        private 
        returns(bool) 
    {
        poolInfo.lpToken.safeTransferFrom(_from, _to, _amount);
        return true;
    }

    /**
     * @notice Secure internal _transferFrom.
     * @param _to The address to.
     * @param _amount The transfer amount.
     */
    function _transfer(address _to, uint256 _amount) private returns(bool) {
        poolInfo.lpToken.safeTransfer(_to, _amount);
        return true;
    }
    
}