// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
/**
* @notice In this example I will show how we can limit
* the number of times a function can be executed. We can 
* do that with a modifier and a state variable set to true
* after first time executed.
*/

contract Initialized is Context {
    address public owner;
    uint256 public start;
    uint256 public val;
    bool public initialized;

    error AlreadyInitialized();

    modifier notInitialized() {
        if (initialized) 
            revert AlreadyInitialized();
        _;
        initialized = true;
    }

    // initialize can replace a constructor, but should only be called once.
    function initialize(uint256 _val) external notInitialized {
        owner = _msgSender();
        val = _val;
        start = block.timestamp;
    }
    // with require(xxx,"string");
    // execution cost 110117 gas.
    // transaction cost 110117 gas.

    // with if (!xxx) revert error();
    // execution cost 110105 gas.
    // transaction cost 110105 gas.
} 