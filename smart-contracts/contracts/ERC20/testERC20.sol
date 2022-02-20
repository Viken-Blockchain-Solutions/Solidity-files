// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestERC20 is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor(uint256 _amount) ERC20("TestERC20", "TESTTOKEN") ERC20Permit("TestERC20") {
        address owner = msg.sender;
        mint(owner, _amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    
    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    } 
    
}