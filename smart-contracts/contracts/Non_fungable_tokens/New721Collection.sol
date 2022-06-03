// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

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
 *         - Supports ERC721Royalty - Royalty Standard.
 *         - Supports OpenSea by implementing { contractURI } method for handeling Royalties. 
 */
/// @custom:security-contact security@vikenblockchain.com
contract MyToken is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, ERC721Royalty, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string public contractURI = "https://ifwsu1awnie4.usemoralis.com/info.json";
    
    constructor(string memory name, string memory ticker) ERC721(name, ticker) {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ifwsu1awnie4.usemoralis.com/json/";
    }

    function mint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}