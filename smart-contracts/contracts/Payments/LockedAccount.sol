/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract LockedAccount {
    address public owner = msg.sender;

    error Code_1()

    receive() external payable {

    }

    function withdraw() external {
        if (!msg.sender == owner) revert Code_1();
        selfdestruct(payable(msg.sender));
    }


}

