// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


/**
* @notice This contract will demonstrate how to use iterable mapping in a smart-contract.
*/
contract IterableMapping {

    // represents the balance of an address.
    mapping(address => uint256) public balances;

    // represents the address is inserted or not.
    mapping(address => bool) public inserted;
    
    // array contains all the keys (adresses).
    address[] public keys;

    /**
    * @notice Set the balance of an address.
    */
    function setKeyValue(address _key, uint256 _val) external {
        // update the balance of the address.
        balances[_key] = _val;

        // if the _key is not inserted, insert the _key.
        if (!inserted[_key]) {
            inserted[_key] = true;
            keys.push(_key);
        }
    }

    /**
    * @notice Get the size of the array of keys which will be total 
    * size of the balances mapping.
    */
    function getSize() external view returns (uint256) {
        return keys.length;
    }

    /**
    * @notice Get the balance of the first address in the mapping by using the keys array. 
    */
    function first() external view returns (uint256) {
        return balances[keys[0]];
    }

    /**
    * @notice Get the balance of the last address in the mapping by using the keys array. 
    */
    function last() external view returns (uint256) {
        return balances[keys[keys.length - 1]];
    }
   
    /**
    * @notice Get the balance of a given index in the mapping by using the keys array. 
    */
    function get(uint256 _i) external view returns (uint256) {
        return balances[keys[_i]];
    }
}