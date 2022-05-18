// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

/** 
 * @notice This contract contains a set of 'Nice to have" modifers.
 * @notice onlyAdmin.
 * @notice notContract.
 * @notice itemExists.
 */


contract Modifers is Context, Ownable {

    address public admin;
    bool public initialized;
    uint256[] public itemArray;

    // errors
    error OnlyAdmin();
    error ContractsNotAllowed();
    error ProxyNotAllowed();
    error AlreadyInitialized();


    /**
     * @notice Checks if the msg.sender is the admin address.
     */
    modifier onlyAdmin() {
        if (!_msgSender() == admin)
            revert OnlyAdmin();
        _;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy.
     * @dev requires the method _isContract(address sender).
     */
    modifier notContract() {
        if (_isContract(_msgSender())) revert ContractsNotAllowed();
        if (_msgSender() == tx.origin) revert ProxyNotAllowed();
        _;
    }

    /**
     * @notice Checks if the called method is already initialzed.
     * @dev requires the method _isContract(address sender).
     */
    modifier notInitialized() {
        if (initialized) 
            revert AlreadyInitialized();
        _;
        initialized = true;
    }

    /**
     * @notice Checks if an _id is in an array.
     * @dev requires the method _isContract(address sender).
     */
    modifier itemExists(uint256 _id) {
        require(_id < itemArray.length, "not in list");
        _;
    }

     /**
     * @notice Checks if address is a contract.
     * @dev It prevents contract from being targeted.
     * @dev Is required to use the notContract() modifier. 
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}