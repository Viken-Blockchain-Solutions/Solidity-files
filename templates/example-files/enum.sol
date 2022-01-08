// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


/**
* @notice This contract will represent a order with an shipping status.
* This ccontract will demonstrate how to combine and use enums in a smart-contract.
*/
contract Enum {
    
    /**
    * @notice enum Status contains multiple status.
    * The different "statuses" are represented as index numbers.
    */
    enum Status {
        None,       // 0
        Pending,    // 1
        Shipped,    // 2
        Completed,  // 3
        Rejected,   // 4
        Canceled    // 5
    }

    /**
    * @notice Status is set as statevariable status.
    */
    Status public status;
    
    /**
    * @notice The shipping Order uses the Status status.
    */
    struct Order {
        address buyer;
        Status status;
    }

    /**
    * @notice an Order array of orders .
    */
    Order[] public orders;


    /**
    * @notice A getter function to return the status as a number.
    */
    function getStatus() public view returns (Status) {
        return status;
    }

    /**
    * @notice A setter function to set the status.
    * @param _status input type is a uint256
    */
    function setStatus(Status _status) external {
        status = _status;
    }

    /**
    * @notice ship() will update the status to Shipped.
    */
    function ship() external {
        status = Status.Shipped;
    }

    /**
    * @notice This wil reset the status to the default value of None.
    */
    function resetStatus() external {
        delete status;
    }
}