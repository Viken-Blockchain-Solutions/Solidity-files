// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./MIntableERC721.sol";

contract CentaurifyBase721 is MintableERC721 {
    uint256 public immutable MAX_SUPPLY;

    /// @dev Code_1: Above MAX_SUPPLY.
    error Code_1();

    modifier maxSupply() {
        if (totalSupply == MAX_SUPPLY) revert Code_1();
        _;
    }
    constructor(string memory _name, string memory _symbol, uint256 _max)
        MintableERC721(_name, _symbol)
    {
        MAX_SUPPLY = _max;
    }

    function mint(address _to, uint256 _tokenId) public override maxSupply {
        super.mint(_to, _tokenId);
    }

    function mintBatch(address _to, uint256 _tokenId, uint256 _amount) public override {
        require(totalSupply + _amount <= MAX_SUPPLY, "MAX_SUPPLY"
        );
        super.mintBatch(_to, _tokenId, _amount);
    }
}