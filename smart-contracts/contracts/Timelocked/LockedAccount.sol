// SPDX-License-Identifier: MIT

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract LockedAccount {
    event Hacked();
    event FuckYou();

    address public owner;

    error Code_1();

    constructor() {
        owner = payable(msg.sender);
    }
    receive() external payable {
        emit Locked();
    }

    function withdraw() external {
        if (!msg.sender == owner) revert Code_1();
        emit Hacked();
        selfdestruct(payable(msg.sender));
    }


}

