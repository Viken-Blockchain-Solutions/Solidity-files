// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Fees is Ownable {

    address public feeAddress;
    uint256 internal withdrawFeePeriod; // 3 months
    uint256 internal withdrawPenaltyPeriod; // 14 days;
    uint256 public constant withdrawFee = 700; // 7% withdraw fee.

    error ExitFeesFailed();

    event ExitWithFees(address indexed user, uint256 amount, uint256 fees);

    /// @notice Internal function to calculate the early withdraw fees.
    /// @notice return feeAmount and withdrawAmount.
    function _calculateFee(uint256 _amount) 
        internal 
        pure 
        returns (
            uint256 feeAmount, 
            uint256 withdrawAmount
        ) 
    {
        feeAmount = _amount * withdrawFee / 10000;
        withdrawAmount = _amount - feeAmount; 
    }

    function setFeeAddress(address newFeeAddress) external onlyOwner {
        feeAddress = address(newFeeAddress);
    }
}