// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IMintableERC721 {
  	// getter for the _ipfsUri mapping
  	function getIpfsUri(uint256 tokenId) external view returns(string memory);

  	// get all nfts owned by given address, returns an array with tokenIds
 	function getAllTokensOwnedBy(address _owner) external view returns(uint256 [] memory);
	
	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) external view returns(bool);

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _uri an ipfs uri for token to
	 */
	function mint(address _to, string memory _uri) external;

}