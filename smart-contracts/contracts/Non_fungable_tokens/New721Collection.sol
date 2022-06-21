// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title  New721Collection.
 * @author @Dadogg80 for Viken Blockchain Solutions.
 *
 * @notice This smart contract is a generic type contract to create Artist Collections,
 *         and list the collection on OpenSea.
 * @dev    This contract contain custom methods and some improvments like:
 *         - Supports ERC721Royalty , built on ERC2981 Royalty Standard.
 *         - Supports OpenSea by implementing { contractURI } method for handeling Royalties.
 */

/// @custom:security-contact security@vikenblockchain.com
contract New721Collection is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    ERC721Royalty,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    event DefaultRoyalty(address indexed royaltyReceiver, uint96 feeNumerator);
    event Mint(address indexed to, uint indexed tokenId, string uri);

    /// @notice Constructor is sets the royalty info and Token details
    /// @dev name The name of the new ERC721.
    /// @dev ticker The ticker of the new ERC721.
    /// @dev royaltyReciever The account that will receive royalty from secondary sales.
    /// @dev royaltyFee The percentage to claim as royalty in BIPS (1000 = 10%).
    constructor(
        string memory name,
        string memory ticker,
        address royaltyReceiver,
        uint96 feeNumerator
    ) ERC721(name, ticker) {
        super._setDefaultRoyalty(royaltyReceiver, feeNumerator);
        emit DefaultRoyalty(royaltyReceiver, feeNumerator);
    }

    /// @notice Required to support OpenSea's royalty method.
    /// @return String with the uri to the metadata json file.
    function contractURI() public pure returns (string memory) {
        return "https://ifwsu1awnie4.usemoralis.com/info.json";
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ifwsu1awnie4.usemoralis.com/json/";
    }

    /// @notice Will mint a new NFT from the passed URI.
    /// @param uri The location of the metadata.
    function mint(string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(_msgSender(), tokenId);
        _setTokenURI(tokenId, uri);

        emit Mint(_msgSender(), tokenId, uri);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
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

    /// @notice Restricted function! Only owner account.
    /// @dev Method used by the owner account to withdraw the native balance from this smart contract.
    function withdraw() external onlyOwner {
        uint amount = address(this).balance;
        payable(address(owner())).transfer(amount);
    }

    /// @notice Restricted function!  Only owner account.
    /// @dev Method will return the native balance of this smart contract.
    function balance() external view onlyOwner returns (uint) {
        return address(this).balance;
    }
}
