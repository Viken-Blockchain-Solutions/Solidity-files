// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./../Admin/Whitelisted.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



/// @title LockedAccount.
/// @author @Dadogg80.
/// @notice This contract will lock any funds transfered into it and destroy the contract at withdrawal like a piggybank.
contract LockedAccount is Whitelisted {
    
    /// @notice Deposit is emited when ETHER is transfered into this smart-contract.
    event Deposit(uint value);

    /// @notice Withdraw is emited when ETHER is transfered out from this smart-contract.
    event Withdraw(uint value);

    /// @notice The deployer of this contract.
    address private owner;

    constructor() {
        owner = payable(msg.sender);
        isWhitelisted[owner] = true;
    }

    /// @notice Receive allows anyone to send ETH or equalent to this contract address.
    receive() external payable {
        emit Deposit(msg.value);
    }

    /// @notice Withdraw all the funds, then destroys the contract.
    /// @dev Restricted to only whitelisted accounts.
    function withdraw() external onlyWhitelisted {
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }

    /// @notice Withdraw a given ERC20 token.
    /// @param token The contract address of the ERC20 to withdraw.
    /// @dev Restricted to only whitelisted accounts.
    function withdrawERC20(IERC20 token) external onlyWhitelisted {
        uint balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}

