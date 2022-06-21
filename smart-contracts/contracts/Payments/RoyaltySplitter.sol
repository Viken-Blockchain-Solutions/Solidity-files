// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";


/// @title RoyaltySplitter.sol
/// @notice RoyaltySplitter is used to act as the royalty receiver of an NFT. 
///         This smart contract will accept both Eth and tokens, and distribute 
///         the value between the accounts according to the shares. 


contract RoyaltySplitter is PaymentSplitter {

    address payable public royalty;

    event RoyaltyContract(address RoyaltyAddress, address[] Payees, uint[] Shares);

    constructor(address[] memory _payees, uint[] memory _shares) PaymentSplitter(_payees, _shares) payable {
        royalty = payable(this);
        emit RoyaltyContract(royalty, _payees, _shares);
    }

}
