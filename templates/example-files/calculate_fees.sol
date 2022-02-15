// SPDX-License-Identifier: MIT    
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Calculate fees from amount.
/// @author Ivo Garofalo
/// @notice This contact is used to demonstrate how we can calculate fees in solidity.
/// @dev All uint256 values are in nominated in Wei.
contract Calculate_fees is Ownable {
  using SafeMath for uint256;


  /// @notice The current performance fee value.
  /// @dev example: 50 = 0.50%, 100 = 1%, 125 = 1.25%, 500 = 5%, 1000 = 10%.
  uint256 public CURRENT_PERFORMANCE_FEE = 700;
  error AmountToLow();



  /// @notice Internal function to calculate the amount of fee to pay with a transaction.
  /// @param _amount The Wei amount to calculate the fee from.
  /// @dev The _amount has to be nominated in Wei.
  /// @return _feeAmount in Wei. 
  function _calculatePerformanceFee(uint256 _amount) external view returns (uint256 _feeAmount) {
      _feeAmount = _amount.mul(CURRENT_PERFORMANCE_FEE).div(10000);     // 24436 gas.
  }

  /// @notice Internal function to calculate the amount of fee to pay with a transaction.
  /// @param _amount The Wei amount to calculate the fee from.
  /// @dev The _amount has to be nominated in Wei.
  /// @return _feeAmount in Wei. 
  function _normalCalculatePerformanceFee(uint256 _amount) external view returns (uint256 _feeAmount) {
      _feeAmount = (_amount * CURRENT_PERFORMANCE_FEE) / 10000;  // 24309 gas.
  }

  /// @notice Function to set a new performance fee.
  /// @param _value The value to represent % when calculating feeAmount.
  /// @dev example: 5 = 0.5%, 10 = 1%, 100 = 10%.
  function _setPerformanceFee(uint256 _value) external onlyOwner {
      CURRENT_PERFORMANCE_FEE = _value;
  }


}