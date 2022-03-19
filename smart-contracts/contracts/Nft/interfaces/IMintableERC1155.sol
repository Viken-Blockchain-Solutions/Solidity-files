// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IMintableERC1155 is IERC1155 {
    
    struct NFTDetails  {
        uint256 id;
        string ipfsUri;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev getter for the _nftDetails mapping, returns struct
     */
    function getNftDetails(uint256 tokenId) external view returns (NFTDetails memory);

}