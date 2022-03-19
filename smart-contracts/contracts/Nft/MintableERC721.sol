// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IMintableERC721.sol";

contract MintableERC721 is ERC721, ERC721Enumerable, IMintableERC721, AccessControl, Ownable {
  using Address for address;
  using Strings for uint256;

  /**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 */
  uint256 public constant UID = 0xcae0bce6885c2fc2d3cf5b4cc1524812ef8a157400828fd542e3a9eaaaa24978;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(BURNER_ROLE, msg.sender);
    _setupRole(URI_MANAGER_ROLE, msg.sender);
  }


  // mapping for ipfs uris
  mapping (uint256 => string) private _ipfsUri;

  /**
   * @dev set a new IPFS URL for tokenId.
   * @param tokenId tokenId to get
   */
  function getIpfsUri(uint256 tokenId) public view returns(string memory){
    return _ipfsUri[tokenId];
  }

  /**
	 * @dev Fired in setIpfsUri()
	 *
	 * @param _by an address which executed update
   @ @param _tokenId tokenId modified
	 * @param _oldVal old _ipfsUri value
	 * @param _newVal new _ipfsUri value
	 */
  event IpfsUriChanged(
    address _by,
    uint256 _tokenId,
    string _oldVal,
    string _newVal
  );

  /**
   * @dev set a new IPFS URL for tokenId.
   * @param _tokenId tokenId to set new Uri
   * @param _newUri new ipfs URI to set
   * Requirements:
   *
   * - `_tokenId` must exist.
   *
   * Emits a {newIpfsUri} event.
   */
  function setIpfsUri(uint256 _tokenId, string memory _newUri) public onlyRole(URI_MANAGER_ROLE){
    require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
    string memory _oldVal = _ipfsUri[_tokenId];
    _ipfsUri[_tokenId] = _newUri;
    emit IpfsUriChanged(msg.sender, _tokenId, _oldVal, _newUri);
  } 
  
  // get all nfts owned by given address, returns an array with tokenIds
  function getAllTokensOwnedBy(address _owner) public view returns(uint256 [] memory){
    require(_owner != address(0), "Token query for the zero address");

    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    }

    uint256[] memory result = new uint256[](tokenCount);

    uint256 _tokenId;
    for (_tokenId = 0; _tokenId < tokenCount; _tokenId++) {
      result[_tokenId] = tokenOfOwnerByIndex(_owner, _tokenId);
    }

    return result;
  }

  string internal theBaseURI = "";

  function _baseURI() internal view virtual override returns (string memory) {
    return theBaseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
  }

  /**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
  event BaseURIChanged(
    address _by,
    string _oldVal,
    string _newVal
  );

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
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function burn(uint256 _tokenId) public onlyRole(BURNER_ROLE) {
    // Delegate to internal OpenZeppelin burn function
    _burn(_tokenId);
  }

  /**
   * @inheritdoc IMintableERC721
   */
  function mint(address _to, string memory _uri) public onlyRole(MINTER_ROLE) {
    uint256 _tokenId = totalSupply();
    _ipfsUri[_tokenId] = _uri;
    // Delegate to internal OpenZeppelin function
    _mint(_to, _tokenId);
  }

  function safeMint(address _to, string memory _uri, bytes memory _data) public onlyRole(MINTER_ROLE) {
    uint256 _tokenId = totalSupply();
    _ipfsUri[_tokenId] = _uri;
    // Delegate to internal OpenZeppelin unsafe mint function
    _mint(_to, _tokenId);

    // If a contract, check if it can receive ERC721 tokens (safe to send)
    if(_to.isContract()) {
		  bytes4 response = IERC721Receiver(_to).onERC721Received(msg.sender, address(0), _tokenId, _data);

		  require(response == IERC721Receiver(_to).onERC721Received.selector, "Invalid onERC721Received response");
    }
  }

  function safeMint(address _to, string memory _uri) public {
    // Delegate to internal safe mint function (includes permission check)
    safeMint(_to, _uri, "");
  }

  /**
   * @inheritdoc ERC721
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
    return interfaceId == type(IMintableERC721).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc ERC721
   */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}