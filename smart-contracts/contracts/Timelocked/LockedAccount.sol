// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./../Admin/Whitelisted.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



/// @title LockedAccount.
/// @author @Dadogg80.
/// @notice This contract will lock any funds transfered into it and destroy the contract at withdrawal like a piggybank.
contract LockedAccount is Whitelisted {
    
    /// @notice Deposit is emited when ether is transfered into this smart-contract.
    event Deposit(uint value);

    /// @notice Withdraw is emited when ether is transfered out from this smart-contract.
    event Withdraw(uint value);

    address public owner;

    constructor() {
        owner = payable(msg.sender);
        isWhitelisted[owner] = true;
    }

    receive() external payable {
        emit Deposit(msg.value);
    }

    /// @notice Withdraw all the funds, then destroys the contract.
    function withdraw() external onlyWhitelisted {
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }

    /// @notice Withdraw a given ERC20 token.
    /// @param token The contract address of the ERC20 to withdraw.
    function withdrawERC20(address token) external onlyWhitelisted {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }
}

