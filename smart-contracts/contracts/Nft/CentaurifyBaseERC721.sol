// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IMintableERC721.sol";

contract CentaurifyBaseERC721 is ERC721, IMintableERC721, AccessControl {
    using Address for address;
    using Strings for uint256;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

    uint256 public totalSupply = 0;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    constructor(string memory _name, string memory _symbol, address _owner) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MINTER_ROLE, _owner);
        _setupRole(URI_MANAGER_ROLE, _owner);
    }

    string internal theBaseURI = "";

    /**
    * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    * token will be the concatenation of the `baseURI` and the `tokenId`. 
    * Override a child contract.
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return theBaseURI;
    }

    /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return 
        bytes(baseURI).length > 0 
        ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) 
        : "";
    }

    /**
    * @dev Fired in setBaseURI()
    *
    * @param _by an address which executed update
    * @param _oldVal old _baseURI value
    * @param _newVal new _baseURI value
    */
    event BaseURIChanged(address _by, string _oldVal, string _newVal);
    
    /**
        * @dev Restricted access function which updates base URI used to construct
        *      ERC721Metadata.tokenURI
        *
        * @param _newBaseURI new base URI to set
        */
    function setBaseURI(string memory _newBaseURI) external onlyRole(URI_MANAGER_ROLE) {
        // Fire event
        emit BaseURIChanged(msg.sender, theBaseURI, _newBaseURI);
        // Update base uri
        theBaseURI = _newBaseURI;
    }

    /**
    * @inheritdoc IMintableERC721
    */
    function exists(uint256 _tokenId) external view returns(bool) {
        // Delegate to internal OpenZeppelin function
        return _exists(_tokenId);
    }

    /**
    * @inheritdoc IMintableERC721
    */
    function mint(address _to, uint256 _tokenId) public virtual onlyRole(MINTER_ROLE){
        totalSupply++;
        // Delegate to internal OpenZeppelin function
        _mint(_to, _tokenId);
    }

    /**
    * @inheritdoc IMintableERC721
    */
    function mintBatch(address _to, uint256 _tokenId, uint256 _n) public virtual onlyRole(MINTER_ROLE) {
        totalSupply += _n;
        
        for (uint256 i = 0; i < _n; i++) {
        // Delegate to internal OpenZeppelin mint function
        _mint(_to, _tokenId + i);
        }
    }

    /**
    * @inheritdoc IMintableERC721
    */
    function safeMint(address _to, uint256 _tokenId, bytes memory _data) public onlyRole(MINTER_ROLE) {
        // Delegate to internal OpenZeppelin unsafe mint function
        _mint(_to, _tokenId);

        // If a contract, check if it can receive ERC721 tokens (safe to send)
        if (_to.isContract()) {
        bytes4 response = IERC721Receiver(_to).onERC721Received(
            msg.sender,
            address(0),
            _tokenId,
            _data
        );

        require(
            response == IERC721Receiver(_to).onERC721Received.selector,
            "Invalid onERC721Received response"
        );
        }
    }

    /**
    * @inheritdoc IMintableERC721
    */
    function safeMint(address _to, uint256 _tokenId) public onlyRole(MINTER_ROLE){
        // Delegate to internal safe mint function (includes permission check)
        safeMint(_to, _tokenId, "");
    }

    /**
    * @inheritdoc IMintableERC721
    */
    function safeMintBatch(address _to, uint256 _tokenId, uint256 _n, bytes memory _data) public onlyRole(MINTER_ROLE) {
        // Delegate to internal unsafe batch mint function (includes permission check)
        mintBatch(_to, _tokenId, _n);

        // If a contract, check if it can receive ERC721 tokens (safe to send)
        if (_to.isContract()) {
        bytes4 response = IERC721Receiver(_to).onERC721Received(
            msg.sender,
            address(0),
            _tokenId,
            _data
        );

        require(
            response == IERC721Receiver(_to).onERC721Received.selector,
            "Invalid onERC721Received response"
        );
        }
    }

    /**
    * @inheritdoc IMintableERC721
    */
    function safeMintBatch(address _to, uint256 _tokenId, uint256 _n) external onlyRole(MINTER_ROLE) {
        // Delegate to internal safe batch mint function (includes permission check)
        safeMintBatch(_to, _tokenId, _n, "");
    }

    /**
    * @inheritdoc ERC721
    */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return
        interfaceId == type(IMintableERC721).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // ************************************************************************************************************************
    // The following methods are borrowed from OpenZeppelin's ERC721Enumerable contract, to make it easier to query a wallet's
    // contents without incurring the extra storage gas costs of the full ERC721Enumerable extension
    // ************************************************************************************************************************

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
        tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
    * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
    */
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view virtual returns (uint256) {
        require(
        index < ERC721.balanceOf(_owner),
        "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[_owner][index];
    }

    /**
    * @dev Private function to add a token to ownership-tracking data structures.
    * @param to address representing the new owner of the given token ID
    * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
    * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
    * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
    * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
    * This has O(1) time complexity, but alters the order of the _ownedTokens array.
    * @param from address representing the previous owner of the given token ID
    * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
        uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

        _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
    * @dev Hook that is called before any token transfer. This includes minting
    * and burning.
    *
    * Calling conditions:
    *
    * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
    * transferred to `to`.
    * - When `from` is zero, `tokenId` will be minted for `to`.
    * - When `to` is zero, ``from``'s `tokenId` will be burned.
    * - `from` cannot be the zero address.
    * - `to` cannot be the zero address.
    *
    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0)) {
        _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to != address(0)) {
        _addTokenToOwnerEnumeration(to, tokenId);
        }
    }
}