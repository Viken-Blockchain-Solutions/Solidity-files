/// SPDX-License_Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Calculate fees from amount.
/// @author Ivo Garofalo
/// @notice This contact is used to demonstrate how we can calculate fees in solidity.
/// @dev All uint256 values are in nominated in Wei.
contract Calculate_fees is Ownable {
  using SafeMath for uint256;


  /// @notice The current performance fee value.
  /// @dev example: 5 = 0.5%, 10 = 1%, 100 = 10%.
  uint256 public CURRENT_PERFORMANCE_FEE = 10;
  error AmountToLow();

  /// @notice Modifier checks that _amount is larger than 0.001 eth or 1000000000000000 Wei.
  /// @param _amount The amount to calculate fees from;
  /// @dev _amount has to be nominated in Wei.
  /// @notice 1e15 = 1000000000000000 or 0.001 eth.
  modifier minValue(uint256 _amount) {
      if (_amount < 1e15) revert AmountToLow();
      _;
  }

  /// @notice Internal function to calculate the amount of fee to pay with a transaction.
  /// @param _amount The Wei amount to calculate the fee from.
  /// @dev The _amount has to be nominated in Wei.
  /// @return _feeAmount in Wei. 
  function _calculatePerformanceFee(uint256 _amount) external view returns (uint256 _feeAmount) {
      _feeAmount = (_amount.div(1000)).mul(CURRENT_PERFORMANCE_FEE);
  }

  /// @notice Function to set a new performance fee.
  /// @param _value The value to represent % when calculating feeAmount.
  /// @dev example: 5 = 0.5%, 10 = 1%, 100 = 10%.
  function _setPerformanceFee(uint256 _value) external onlyOwner {
      CURRENT_PERFORMANCE_FEE = _value;
  }


}