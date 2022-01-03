// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/** 
 * @notice This contract with let an user deposit funds into a Vault with a given lockperiod.
 *          After the lockperiod, the user can withdraw the funds and the accumulated rewards 
 *          back to their wallet.
 */
contract StakingContract is Context, Ownable {
    using SafeMath for uint256;

    IERC20 public stakeToken;

    mapping(address => Vault) internal VaultsMapping;

    event StakingToken(address stakeToken);

    event AddedToVault(uint256 staked, address stakeholder);

    event ReceiveReverted(uint256 value);

    /**
     * @notice Vault to hold the stakeholder data.
     * @param isStaking Bool.
     * @param tokenAddress Address of staked ERC20.
     * @param staked The amount of this stakeholder id.   
     * @param reward The reward amount of this stakeholder id.   
     */
    struct Vault {
        bool isStaking;
        address tokenAddress;
        uint256 amount;
        uint256 reward;
    }

    /**
     * @notice receive function reverts and returns the funds to the sender.
     */ 
    receive() external payable {
        emit ReceiveReverted(msg.value);
        revert("not payable receive");

    }

    /**
     * @notice Authorizes this StakingContract to spend the _msg.senders token (ERC20).
     * @param _erc20Address Address of an ERC20 used as stakingToken.
     */
    function approveToSpendToken(address _erc20Address) external {
        IERC20 erc20 = IERC20(_erc20Address);
        uint256 max = 2**256 - 1;
        erc20.approve(address(this), max);
    }

    /**
     * @notice A method to set the token to stake.
     * @param _tokenAddress The TokenAddress to stake.
     */
    function setToken(address _tokenAddress) external onlyOwner {
        stakeToken = IERC20(_tokenAddress);

        emit StakingToken(_tokenAddress);
    }

    /**
     * @notice Add stakeholder and stake amount to the vault.
     * @param _stake Amount to be staked.
     * @dev Checks allowance and calls safeAppprove() if needed.
     */
    function addToVault(uint256 _stake) external returns (bool) {
        if (_stake <= 0 && msg.sender == address(0)) revert("Zero values.");
        
        uint256 amount = _stake;
        _stake = 0;
        
        VaultsMapping[msg.sender] = Vault(
            true,
            address(stakeToken),
            amount,
            0
        );

        require(
            stakeToken.transferFrom(address(msg.sender), address(this), amount),
            "AddToVault failed"
        );

        emit AddedToVault(amount, msg.sender);

        return true;
    }
}