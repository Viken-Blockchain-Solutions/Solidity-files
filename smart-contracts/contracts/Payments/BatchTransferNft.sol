// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title Spread Dapp, ERC721 Edition Ethereum.
/// @author @dadogg80, Viken Blockchain Solutions.
/// @notice Transfer your NFT's to multiple accounts in one transaction.
/// @dev The purpose of this smart-contract was to create an smart contract that would allow us to transfer a batch of ntf's to multiple accounts.


contract BatchTransferNft is Ownable {
    
    /// @dev authentication error.
    error Error_1();

    /// @dev thrown by receive function.
    error Error_2();
    error Error_3();

    /// @dev thrown if zero values.
    error ZeroValues();

    event ApprovalSet(IERC721 collection);
    event TransferID(uint Id);
    
    constructor() {
    }

    modifier noZeroValues(address[] calldata recipients, uint256[][] calldata ids) {
      if (recipients.length <= 0 ||  ids.length <= 0) revert ZeroValues();
      _;
    }

    modifier noZeroValuesERC20(address[] calldata recipients, uint256[] calldata values) {
      if (recipients.length <= 0 ||  values.length <= 0) revert ZeroValues();
      _;
    }

    /// @dev Receive function.
    receive() external payable {
        revert Error_2();
    } 

    /// This will allow you to batch transfers of an mainnet asset like Ethereum, Matic, etc, to multiple accounts.
    /// @param collection The collection to transfer from.
    /// @param recipients List with the recipient accounts.
    /// @param ids List with the tokenIds to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: [value,value,value].
    function spreadERC721(IERC721 collection, address[] calldata recipients, uint256[][] calldata ids) 
        external 
        payable 
        noZeroValues(
            recipients, 
            ids
        ) 
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256[] memory _ids = ids[i];
            for(uint256 k = 0; k < _ids.length; k++) {
                collection.transferFrom(msg.sender, recipients[i], _ids[k]);
                emit TransferID(_ids[k]);
            }
        }
    }

    /// This will allow you to batch transfers of erc20 tokens, to multiple accounts.
    /// @param token The ERC20 contract address
    /// @param recipients List with the recipient accounts.
    /// @param values List with values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: [value,value,value].
    function spreadERC20(IERC20 token, address[] calldata recipients, uint256[] calldata values) external noZeroValuesERC20(recipients, values) {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        token.transferFrom(msg.sender, address(this), total);
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    /// This is a cheaper way to batch transfer erc20 tokens, to multiple accounts.
    /// @param token The ERC20 contract address
    /// @param recipients List with the recipient accounts.
    /// @param values List with values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: [value, value, value].
    function spreadERC20Simple(IERC20 token, address[] calldata recipients, uint256[] calldata values) external noZeroValuesERC20(recipients, values) {
        for (uint256 i = 0; i < recipients.length; i++)
            token.transferFrom(msg.sender, recipients[i], values[i]);
    }

    /// This will allow the owner account to save any stuck erc20 tokens.
    /// @param collection The ERC721 collection contract address.
    /// @param ids List with the tokenIds to transfer to the corresponding recipient.
    /// @dev Restricted by onlyOwner modifier.
    function saveERC721(IERC721 collection, uint256[][] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256[] memory _ids = ids[i];
            for(uint256 k = 0; k < _ids.length; k++) {
                collection.transferFrom(address(this), _msgSender(), _ids[k]);
                emit TransferID(_ids[k]);
            }
        }
    }
    
    /// This will allow the owner account to save any stuck erc20 tokens.
    /// @param token The ERC20 contract address.
    /// @dev Restricted by onlyOwner modifier.
    function saveERC20(IERC20 token) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(address(msg.sender), amount);
    }

    /// This will allow the owner account to save any stuck main asset.
    /// @dev Restricted by onlyOwner modifier.
    function saveAsset() external onlyOwner {
        uint256 asset = address(this).balance;
        payable(msg.sender).transfer(asset);
    }
}