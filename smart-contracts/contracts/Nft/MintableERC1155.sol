// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// Inheritances
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract MintableERC1155 is ERC1155PresetMinterPauser {

    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");
    using Counters for Counters.Counter;
    /**
    will track the total collections (ids), 
    increment when create a new Collection by 1, 
    can't decrease (can't delete created ids for collections)
     */
    Counters.Counter private _totalSupply;
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract. (ERC1155PresetMinterPauser)
     */
    constructor(string memory uri) ERC1155PresetMinterPauser(uri) {
        _setupRole(URI_MANAGER_ROLE, _msgSender());
    }

    struct NFTDetails  {
        uint256 id;
        string ipfsUri;
    }

    // mapping for ipfs uris
    mapping (uint256 => NFTDetails) private _nftDetails;


    /**
     * @dev getter for the _nftDetails mapping, returns struct
     */
    function getNftDetails(uint256 tokenId) public view returns(NFTDetails memory){
        return _nftDetails[tokenId];
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view returns(uint256){
        return _totalSupply.current();
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
    * - the caller must have the `URI_MANAGER_ROLE`.
    *
    * Emits a {newIpfsUri} event.
    */
    function setIpfsUri(uint256 _tokenId, string memory _newUri) public {
        require(hasRole(URI_MANAGER_ROLE, _msgSender()), "ERC1155: must have URI MANAGER role to change uri");
        require(_tokenId <= totalSupply(), "ERC1155: operator query for nonexistent token");
        string memory _oldVal = _nftDetails[_tokenId].ipfsUri;
        _nftDetails[_tokenId].ipfsUri = _newUri;
        emit IpfsUriChanged(msg.sender, _tokenId, _oldVal, _newUri);
    } 

    /**
     * @dev mint new nft collection
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function newCollection(uint256 amount, string memory uri) public {
        uint256 _id = totalSupply();
        NFTDetails memory _newCollection = NFTDetails({id: _id, ipfsUri: uri});
        _nftDetails[_id] = _newCollection;
        mint(msg.sender, _id, amount, "");
        _totalSupply.increment();
        // verify the ID match total supply (should always match)
        assert(_nftDetails[_id].id == _id);
    }
}