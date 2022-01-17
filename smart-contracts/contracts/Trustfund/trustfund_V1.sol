// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20TimeLockedTrustfund is Ownable {

    address public admin;
    address public reserve;
    address public beneficiary;

    uint public ContractBalance;
    uint public endTime;
    
    bool public isAdmin;
    bool public isReserve;
    bool public isOwner;
  
    IERC20[] tokens;
    /// Mappings
    
    
    /// Events
    event ERC20Deposit(uint amount, address sender, string tokenName);
    event depositDone(uint amount, address indexed depositedTo);
    event InitiatedTrustFund(
        address beneficiary,
        address admin,
        address reserve,
        uint duration,
        uint endTime
    );
    event Withdrawn(address beneficiary);
    
    /// Errors
    error LowFunds(string description);
    error OnlyAdmins(bool isAdmin, bool isOwner, bool isReserve);
    error OnlyOwners(string description);
    

    function initiate(address _beneficiary, address _admin, address _reserve) external onlyOwner {
        beneficiary = payable(_beneficiary);
        admin = _admin;
        reserve = _reserve;

        ///@dev duration is 10 years calculated into seconds.
        uint duration = 52 weeks * 10;
        endTime = block.timestamp + duration;
        
        emit InitiatedTrustFund(beneficiary, admin, reserve, duration, endTime);
    }
    
    /// Should deposit ERC20 tokens into the contract
    ///@param _token  The address of the ERC20 token deposited
    ///@param _amount The amount of ether in WEI, to deposit
    function ERC20deposit(address _token, uint _amount) public {
        ERC20 token = ERC20(_token);
        if (token.allowance(msg.sender, address(this)) < _amount) {
            token.approve(address(this), _amount);
        }

        token.transferFrom(msg.sender, address(this), _amount);
        
        string memory tokenName = token.name();
        tokens.push(IERC20(token));

        emit ERC20Deposit(_amount, msg.sender, tokenName);
    }


    /// Should deposit ETH into the contract
    function ETHdeposit() public payable returns (uint) {
        require(msg.value != 0, "Can't send zero value");
        ContractBalance += msg.value;

        emit depositDone(msg.value, msg.sender);

        return ContractBalance;
    }
    
    function getBalance() public view returns (uint){
        return ContractBalance;
    }
    function getERC20Balance(IERC20 _token) public view returns (uint){
        return _token.balanceOf(address(this));
    }


    function approveWithdraw() external returns (bool approved) {
        require(beneficiary == msg.sender || admin == msg.sender || Ownable.owner() == msg.sender || reserve == msg.sender, "TrustFund: Only an valid address can call this function!");
        
        if(msg.sender == admin) {
            isAdmin = true;
        }
        if(msg.sender == Ownable.owner()) {
            isOwner = true;
        }
        if(msg.sender == reserve) {
            isReserve = true;
        }
        
        if(isAdmin && isOwner || isAdmin && isReserve || isOwner && isReserve) {
            require(_ERC20withdraw(), "Withdraw failed!");
            return true;
        }   
        if(beneficiary == msg.sender) {
            require(
                endTime <= block.timestamp, "TrustFund: TrustFund is not open for withdraws yet!"
            );
            require(_ERC20withdraw(), "Withdraw failed!");
            return true;
        }
        return false;
    }
    

    // Returns the deposited tokens address.
    function getTokens() public view returns ( IERC20[] memory ) {
        return tokens;
    }
    
    function _ERC20withdraw() internal returns (bool success) {
        isAdmin = false;
        isReserve = false;
        isOwner = false;
        
        for (uint i = 0; i < tokens.length; i++) {
            uint tokenBalance = tokens[i].balanceOf(address(this));
           
            if (tokenBalance > 0) {
                tokens[i].transfer(beneficiary, tokenBalance);
            }
        } 

        _ETHwithdraw();
        
        emit Withdrawn(beneficiary);
        
        return true;
    }

    function _ETHwithdraw() internal returns (uint amount){
        require(ContractBalance >= 0);
        
        uint _amount = ContractBalance;
        
        ContractBalance -= _amount;
        
        payable(beneficiary).transfer(_amount);
        
        return ContractBalance;
    }




    // Transfers the funds to the Owner account and removes the smart-contract from the blockchain
    function destroyContract() public onlyOwner() {
        address _owner = Ownable.owner();
        if (_owner != msg.sender) revert OnlyOwners("TrustFund: Only the OWNER can execute selfdestruct!");

        address addr = payable(address(_owner));
        
        selfdestruct(payable(addr));
    }


}