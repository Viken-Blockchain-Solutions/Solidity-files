// SPDX-License-Identifier: MIT


pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract testERC20 is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor() ERC20("testERC20", "TESTTOKEN") ERC20Permit("testERC20") {
        address owner = msg.sender;
        mint(owner, 100000000);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}