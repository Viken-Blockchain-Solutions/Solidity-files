// SPDX-License-Identifier: MIT    
pragma solidity ^0.8.11;

contract TakeFees {

    address public admin;
    address public treasury;
    address public token;

    uint256 public constant MAX_PERFORMANCE_FEE = 2000; // 20%
    uint256 public constant MAX_CALL_FEE = 500; // 5%
    uint256 public constant MAX_WITHDRAW_FEE = 1000; // 10%
    uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 120 hours; // 5 days

    uint256 public performanceFee = 500; // 5%
    uint256 public callFee = 25; // 0.25%
    uint256 public withdrawFee = 300; // 3%
    uint256 public withdrawFeePeriod = 72 hours; // 3 days
    
    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 cakeAtLastUserAction; // keeps track of Olive deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
    }

    mapping(address => UserInfo) public userInfo;

    modifier onlyAdmin(){
        require(msg.sender = admin, "Only Admin");
        _;
    }

    function takeFees() public {
        uint256 currentAmount = 1212;
        
        if (block.timestamp < userInfo.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 currentWithdrawFee = currentAmount.mul(withdrawFee).div(10000);
            token.safeTransfer(treasury, currentWithdrawFee);
            currentAmount = currentAmount.sub(currentWithdrawFee);
        }
    }
 /**
     * @notice Withdraws from funds from the Olive Vault
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);

        uint256 bal = available();
        if (bal < currentAmount) {
            uint256 balWithdraw = currentAmount.sub(bal);
            IMasterChef(masterchef).withdraw(poolId, balWithdraw);
            uint256 balAfter = available();
            uint256 diff = balAfter.sub(bal);
            if (diff < balWithdraw) {
                currentAmount = bal.add(diff);
            }
        }
    }

     /**
     * @notice Sets performance fee
     * @dev Only callable by the contract admin.
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyAdmin {
        require(_performanceFee <= MAX_PERFORMANCE_FEE, "performanceFee cannot be more than MAX_PERFORMANCE_FEE");
        performanceFee = _performanceFee;
    }

    /**
     * @notice Sets call fee
     * @dev Only callable by the contract admin.
     */
    function setCallFee(uint256 _callFee) external onlyAdmin {
        require(_callFee <= MAX_CALL_FEE, "callFee cannot be more than MAX_CALL_FEE");
        callFee = _callFee;
    }

    /**
     * @notice Sets withdraw fee
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyAdmin {
        require(_withdrawFee <= MAX_WITHDRAW_FEE, "withdrawFee cannot be more than MAX_WITHDRAW_FEE");
        withdrawFee = _withdrawFee;
    }

    /**
     * @notice Sets withdraw fee period
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod) external onlyAdmin {
        require(
            _withdrawFeePeriod <= MAX_WITHDRAW_FEE_PERIOD,
            "withdrawFeePeriod cannot be more than MAX_WITHDRAW_FEE_PERIOD"
        );
        withdrawFeePeriod = _withdrawFeePeriod;
    }
}