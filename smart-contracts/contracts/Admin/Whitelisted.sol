// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/// @title Whitelisted.
/// @author @Dadogg80.
/// @notice This contract is used to whitelist addresses.

contract Whitelisted {

    /// @notice Mapping takes an address and returns true if whitelisted.
    mapping(address => bool) internal isWhitelisted;
    
    address[] private list;

    /// @notice Error: Not authorized.
    /// @dev Error codes are described in the documentation.
    error Code_1();

    /// @notice Modifier used to check if caller is whitelisted. 
    modifier onlyWhitelisted() {
        if (!isWhitelisted[msg.sender]) revert Code_1();
        _;
    }

    /// @notice Whitelist an address.
    /// @param account The address to whitelist.
    /// @dev Call restricted to only whitelisted addresses.
    function addToWhitelist(address account) external onlyWhitelisted {
        isWhitelisted[payable(address(account))] = true;
        list.push(account);
    }

    /// @notice Return the whitelist
    /// @dev Call restricted to only whitelisted addresses.
    function getList() external view onlyWhitelisted returns (address[] memory){
        return list;
    }

}
