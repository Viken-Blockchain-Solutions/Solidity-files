// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/** 
 * @notice This contract will let a user deposit funds into a Vault.
 */
contract StakingContract is Context, Ownable {
    using SafeMath for uint256;

    enum Status {
      None,
      Staking,
      Finished
    }

    /**
     * @notice Vault to hold the stakeholder data.
     * @param isStaking Bool.
     * @param tokenAddress Address of staked ERC20.
     * @param staked The amount of this stakeholder id.   
     * @param reward The reward amount of this stakeholder id.   
     */
    struct Vault {
        Status status;
        address tokenAddress;
        uint256 amount;
        uint256 reward;
    }
    
    Status public status;

    IERC20 public token;

    mapping(address => Vault) public VaultsMapping;

    event StakingToken(string Name, address stakeToken);

    event StakedInVault(uint256 staked, address stakeholder);
    
    event StakeWithdrawn(address stakeholder, uint256 amount);

    event ReceiveReverted(uint256 value);



    constructor(address _tokenAddress) {
       stakeToken = IERC20(_tokenAddress);
    } 
    /**
     * @notice receive function reverts and returns the funds to the sender.
     */ 
    receive() external payable {
        emit ReceiveReverted(msg.value);
        revert("not payable receive");

    }

    /**
     * @notice Add stakeholder and stake amount to the vault.
     * @param _stake Amount to be staked.
     * @dev Will fail if approval is not given.
     */
    function addStake(uint256 _stake) external returns (bool) {
        if (_stake <= 0 && msg.sender == address(0)) revert("Zero values.");
        
        uint256 amount = _stake;
        _stake = 0;
        
        VaultsMapping[msg.sender] = Vault(
            status = Status.Staking1,
            address(stakeToken),
            amount,
            0
        );

        require(
            stakeToken.transferFrom(address(msg.sender), address(this), amount),
            "AddToVault failed"
        );

        emit StakedInVault(amount, msg.sender);

        return true;
    }

    /**
    * @notice Get the balance of the staking contract..
    */
    function getContractBalance() public view returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }


    /**
    * @notice Withdraw the staked amount.
    */
    function WithdrawStakedAmount() public returns (bool) {
        uint256 _amount = VaultsMapping[msg.sender].amount;
        uint256 _reward = VaultsMapping[msg.sender].reward;
        VaultsMapping[msg.sender].amount = 0;
        VaultsMapping[msg.sender].status = Status.Unstaked;

        require(stakeToken.transfer(msg.sender, _amount.add(_reward)), 
            "Withdraw Failed!"
        );

        emit StakeWithdrawn(msg.sender, _amount);
        
        return true;
    }
}