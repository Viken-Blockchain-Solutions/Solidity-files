// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract TicketMaster is Context, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_WITHDRAW_FEE = 100; // 10%
    uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 120 hours; // 5 days

    uint256 public performanceFee = 50; // 5%
    uint256 public withdrawFee = 30; // 3%
    uint256 public withdrawFeePeriod = 72 hours; // 3 days


    /**
     * @notice Struct with the staking data of each user.
     * @param totalShares The amount of CENT a user is staking.
     * @param lastUserInteraction Block.timestamp of the last user interaction.
     * @param sharesAtLastUserInteraction Total amount of shares the user had at their last interaction.
     */
    struct UserInfo {
        uint256 amount; // amount of tokens in vault.
        uint256 rewardPending; // pending reward.
        uint256 userShares;
        uint256 lastDeposit;    
        uint256 sharesAtLastInteraction;
        uint256 lastUserInteraction;
    }

    /**
     * @notice VaultInfo Struct with the staking data of the pool.
     * @param token Address of staked token.
     * @param allocPoint The amount of allocation points assigned to this pool.
     * @param lastRewardBlock Last block number that CENT distribution occures.
     * @param accTokenPerShare Accumulated Tokens per share, times 1e12.
     * @param totCentStakedInPool Accumulated Tokens staked in Vault.
    */
    struct VaultInfo {
        IERC20 token;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 totCentStakedInVault;
        uint256 startBlock;
        uint256 endBlock;
    }

    VaultInfo public vaultInfo;
    mapping (address => UserInfo) public userInfo;

    address public feeAddress;
    
    uint256 public sharesPerBlock;
    uint256 public startBlock;
    uint256 public bonus_multiplier = 0;

    /**
     * @notice Constructor.
     * @param _token: erc20 token contract.
     * @param _admin: address of the admin.
     * @param _treasury: address of the treasury (collects fees).
     */
    constructor(IERC20 _token, address _admin, address _treasury) {
        token = _token;
        admin = _admin;
        treasury = _treasury;
        feeAddress = _feeAddress;

        // Infinite approve
        //IERC20(_token).safeApprove(address(singleStaking), 2**255-1);
    }

   /**
     * @notice Checks if the msg.sender is a contract or a proxy.
     */
    modifier notContract() {
        require(!_isContract(_msgSender()), "contract not allowed");
        require(_msgSender() == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier notInitialized() {
        if (initialized) revert OnlyOnce();
        _;
        initialized = true;
    }

    /**
     * @notice Checks if the msg.sender is the admin address.
     */
    modifier onlyAdmin() {
        if (_msgSender() != admin) revert NotAuthorized();
        _;
    }    
    
    /**
     * @notice Checks if the msg.sender is the admin address.
     */
    modifier onlyAdmin() {
        if (_msgSender() != admin) revert NotAuthorized();
        _;
    }


    /**
     * @notice Deposits funds into the Vault.
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit.
     */
    function deposit(uint256 _amount) external whenNotPaused notContract {
        if (_amount <= 0) revert NonZeroValues();

        uint256 vault = getBalance(address(this));
        token.safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 currentShares = 0;

        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(vault);
        } else {
            currentShares = _amount;
        }

        userInfo[_msgSender].shares.add(currentShares);
        userInfo[_msgSender].lastDepositedTime = block.timestamp;

        totalShares = totalShares.add(currentShares);

        userInfo[_msgSender].tokenAtLastUserAction = userInfo[_msgSender].shares.div(totalShares);
        userInfo[_msgSender].lastUserActionTime = block.timestamp;

        _earn();

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }



}