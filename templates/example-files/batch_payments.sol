// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract BatchPayments is Context {
    using SafeERC20 for IERC20;



    function batchEther(address[] calldata recipients, uint256[] calldata values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(_msgSender()).transfer(balance);
    }


    /// @notice Costs 77093 gas to tranfer 6e18 to three address.  costs 7351 gas less to execute.
    function batchERC20(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            token.safeTransferFrom(_msgSender(), recipients[i], values[i]);
    }
}