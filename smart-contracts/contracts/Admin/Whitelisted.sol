// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/// @title Whitelisted.
/// @author @Dadogg80.
/// @notice This contract is used to whitelist accounts.

contract Whitelisted {
    
    /// @dev Array with whitelisted accounts.
    address[] private Whitelist;
    
    /// @dev Mapping takes an address and returns true if account is whitelisted.
    mapping(address => bool) internal isWhitelisted;
    
    /// @notice Error: Not authorized.
    /// @dev Error codes are described in the documentation.
    error Code_1();

    /// @dev Modifier used to check if msg.sender is whitelisted. 
    modifier onlyWhitelisted() {
        if (!isWhitelisted[msg.sender]) revert Code_1();
        _;
    }

    /// @dev Constructor whitelists the deployer account.
    constructor() {
        isWhitelisted[payable(address(msg.sender))] = true;
        Whitelist.push(msg.sender);
    }

    /// @notice Whitelist an account.
    /// @param account The address of account to whitelist.
    /// @dev Call restricted with onlyWhitelisted modifier.
    /// @dev Only a whitelisted account, can add a new account to the whitelist.
    function addToWhitelist(address account) external onlyWhitelisted {
        isWhitelisted[payable(address(account))] = true;
        Whitelist.push(account);
    }

    /// @notice Return the array with whitelisted accounts.
    /// @dev Can only be called by an whitelisted account.
    function getList() external view returns (address[] memory){
        if (!isWhitelisted[msg.sender]) revert Code_1();
        return Whitelist;
    }



}
