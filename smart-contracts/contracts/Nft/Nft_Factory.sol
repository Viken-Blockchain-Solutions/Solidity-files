//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./CentaurifyBaseERC1155.sol";
import "./CentaurifyBaseERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract NFT_Factory is Context {
    event Deployed(address addr, address owner);

    function deploy1155(address _owner, uint _salt) external {
        CentaurifyBaseERC1155 _contract = new CentaurifyBaseERC1155{salt: bytes32(_salt)}(_owner);
        emit Deployed(address(_contract), address(_owner));
    }

    function deploy721(string memory _name, string memory _symbol, address _artist, uint _salt) external {
        CentaurifyBaseERC721 base721 = new CentaurifyBaseERC721{salt: bytes32(_salt)}(_name, _symbol, _artist);
        emit Deployed(address(base721), address(_artist));
    }

    function getAddress(bytes memory bytecode, uint _salt) 
        external 
        view 
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), _salt, keccak256(bytecode)
            )
        );
        return address(uint160(uint(hash)));
    }

    function getByteCode1155(address owner) public pure returns (bytes memory) {
        bytes memory bytecode = type(CentaurifyBaseERC1155).creationCode;
        return abi.encodePacked(bytecode, abi.encode(owner));
    }

    function remove() external {
        selfdestruct(payable(address(_msgSender())));
    }
}