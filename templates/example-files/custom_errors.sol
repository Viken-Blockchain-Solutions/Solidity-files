// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
* require, revert, assert
* - gas refund, state updates are reverted
* custom error - saves gas
*/
contract Errors is Ownable {

    uint public num = 123;

    // declare a custom Error
    error CustomError(address caller, uint i);

    // demonstrates how to use require
    function testRequire(uint256 _i) public pure {
        require(_i <= 10, "index to high");
    }

    // demonstrates how to use revert
    function testRevert(uint256 _i) public pure {
        if (_i > 10) {
            revert("index to high");
        }
    }

    // demonstrates how to use assert to check if a value is true 
    function testAssert() public view {
        assert(num == 123); 
    }
    

    function foo(uint256 _i) public {
        num += 1;
        require(_i < 10);
    }

    // demonstrates how to use a custom error
    function testCustomError(uint256 _i) public {
        if (_i > 10) {
            revert CustomError(msg.sender, _i);
        }
    }
}