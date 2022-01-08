// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
* 2 ways to call parent constructors.
* Order of initialization.
*/



/**
* @notice Mom is a parent contract of the Child contract.
*/
contract Mom {
    string public firstName;

    constructor(string memory _firstName) {
        firstName = _firstName;
    }
}

/**
* @notice Dad is a parent contract of the Child contract.
*/
contract Dad {
    string public lastName;

    constructor(string memory _lastName) {
        lastName = _lastName;
    }
}

/**
* @notice Child1 has Mom and Dad as parent contracts.
*         Child1 will make a call to the constructor 
*         of Mom and Dad by adding them directly into
*         the contract header like below.
*/
contract Child1 is Mom("FirstName"), Dad("lastName") {
    
}

/**
* @notice Child2 has Mom and Dad as parent contracts.
*         Child2 will make a call to the constructor 
*         of Mom and Dad by adding them directly into
*         the constructor header like below.
*/
contract Child2 is Mom, Dad {

    constructor(string memory _firstName, string memory _lastName) Mom(_firsName) Dad(_lastName) {
        // here you can add your code as nomal

    }
}

/**
* @notice Child3 has Mom and Dad as parent contracts.
*         Child3 will make a call to the constructor 
*         of Mom and Dad by adding them directly into
*         the contract header and the constructor header like below.
*/
contract Child3 is Mom("FirstName"), Dad {

    constructor(string memory _lastName) Dad(_lastName) {
        // here you can add your code as normal

    }
}
