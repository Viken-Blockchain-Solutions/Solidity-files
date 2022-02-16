// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BatchPayments {
    error Reverted();

    event EthTransfer(address indexed Payer);
    
    function recieve() external payable {
        revert Reverted();
    }
    // 57620 gas
    function batchEtherPayment(address[] calldata recipients, uint256[] calldata values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(msg.sender).transfer(balance);
        
        emit EthTransfer(msg.sender);
    }


    /// @notice Costs 71365 gas to tranfer total 6e18 to three address.  costs 7351 gas less to execute.
    function batchERC20Payment(
        IERC20 token, 
        address[] calldata recipients, 
        uint256[] calldata values
    ) external {
        for (uint256 i = 0; i < recipients.length; i++)
            token.transferFrom(msg.sender, recipients[i], values[i]);
    }
}