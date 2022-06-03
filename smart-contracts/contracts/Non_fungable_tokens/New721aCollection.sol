// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "erc721a/contracts/ERC721A.sol";

/**
 * @title  New721aCollection.
 * @author @Dadogg80 for Viken Blockchain Solutions. 
 *
 * @notice This smart contract is a generic type contract to create Artist Collections 
 *         based on the ERC721A improved implementation { developed by chiru-labs } of the IERC721 standard that 
 *         supports minting multiple tokens for close to the cost of one.
 *
 * @dev    This contract contain custom methods and some improvments like:
 *         - Custom errors for error handling.
 *         - Supports ERC2981 - Royalty Standard.
 *         - Supports OpenSea by implementing { contractURI } method for handeling Royalties. 
 */

 contract New721Collection is ERC721A {

    constructor() ERC721A("Input NAME", "INPUT TICKER") {}

    /// @notice Mint a set amount of new tokens.
    /// @param quantity the amount of new tokens to mint.
    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(msg.sender, quantity);
    }

}
