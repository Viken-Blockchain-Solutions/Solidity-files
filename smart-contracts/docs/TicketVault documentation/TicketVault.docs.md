# TicketVault - Erc20 SingleStaking with rewards distribution

## **Table of contents**

* [Introduction](TicketVault\_docs.md#introduction)
* [How-To](TicketVault\_docs.md#how-to)
* [Smart-contract](TicketVault\_docs.md#smart-contract)
  * [TicketVault Code](TicketVault\_docs.md#ticketvault-code-description)
    * [Constructor](TicketVault\_docs.md#constructor)
    * [Enum Status description](TicketVault\_docs.md#enum-status-description)
    * [Structs](#structs)
    * [Custom errors](TicketVault\_docs.md#custom-errors)
    * [Methods](#methods)
      * [Public methods](TicketVault\_docs.md#public-methods)
      * [Restricted methods](TicketVault\_docs.md#restricted-methods)
      * [Private methods](TicketVault\_docs.md#private-methods)

***

## Introduction

_TicketVault.sol is a smart contract written in Solidity language._

Context:

_We wanted to develop and deploy a smart contract that would allow us to incentivize and reward our community, for being long-term token HODLERS, contributing to our community, and supporting our project._

_We decided that Staking would be the safest and best solution to reach our goal, to distribute rewards among those who wants to stake their tokens with us long-term._

_TicketVault is a custom developed smart-contract for single ERC20 staking and rewards distribution._&#x20;

_With this documentation, we will give you an in-depth description of the features in this smart contract._&#x20;

## How To

* [Installation guide](../../#instructions)
* [Step-by-Step tutorial](TicketVault\_docs.md#step-by-step-tutorial)

### Step-by-step tutorial

_To be able to follow this step-by-step tutorial, please be sure to follow the_ [_installation guide_](../../#instructions)_, and that you run the_ [_unit tests_](../../#test) _and they passed without errors before continuing with the following steps._

#### 1. **Step One**  

* Deploy `TicketVault` staking contract.  

![Constructor screenshot](../../docs/TicketVault\_constructor.png)

* Before we can deploy the TicketVault contract, there are a couple of variables that are optional to change inside the contract constructor. These variables are located at line `110`, `112`, and `113`.

  1. `stakingPeriod` is the total number of weeks for this staking vault.  
      * The default `stakingPeriod` value is set to 13 weeks (\~3 months).  

  2. `withdrawPenaltyPeriod` is the number of weeks where rewards are being accumulated.  
      * Within this `WithdrawPenaltyPeriod`, if a stakeholder wants to withdraw their position and exit the staking pool, they will not get their accumulated rewards.  
      * The default `WithdrawPenaltyPeriod` value is set to 4 weeks (\~1 month).  

  3. `withdrawFee` is the percentage value of the withdrawal fee.  
      * Example fee values:  

       * 0.1% fee, use value `10`.  

       * 5% fee, use value `500`.  

       * 10% fee, use value `1000`.  

       * Default `withdrawFee` value is set to `700` (7%).  

* With these variables set in the contract code, we can now deploy the TicketVault to the network of your choice.  

  * Open [1_deploy_contracts.js](/scripts/1_deploy_contracts.js), at line `8`, change `CONTRACT_ADDRESS` with the ERC20 contract address you want to use.  

  * In your terminal, go to folder `../smart_contracts`, and enter the code below to deploy the TicketVault smart-contract. 
  
  ```bash
  npx hardhat run scripts/1_deploy_contracts.js --network NETWORKNAME 
  ```  
  
  * Wait until you see the deployment confirmation and contract address from etherscan like below.
  
  
  ```text
  Deploying contracts with the account: 0x2fa005F3e5a5d35D431b7B8A1655d2CAc77f22AB

  ----------------------------------------------------------------------------------
  |    Deployment Status  :                                                          
  |       Contract owner  :        0x2fa005F3e5a5d35D431b7B8A1655d2CAc77f22AB
  |       Fee address     :        0x2fa005F3e5a5d35D431b7B8A1655d2CAc77f22AB
  |
  |  ------------------------------------------------------------------------------
  |    Contract deployed  :
  |       TokenAddress    :        0x938f689d828D6d105BAc52F9DE605d6C6CCa1CD1
  |       TicketVault     :        0x6Fa408C20cEC935e4e0F3227Fbb4B12499Cb99F3
  |       StakePeriod     :        7862400 Sec.
  ----------------------------------------------------------------------------------
  ```
* Now you can verify the contract on etherscan.

#### 2. **Step two**

* Add Rewards.
* 

## Smart-Contracts
1. [TicketVault.sol](TicketVault.sol)
2. [Fees.sol](Fees.sol)

## TicketVault Code
_Description of the code in TicketVault.sol._

### **Constructor**

* Parameter.  

  * `address TokenAddress`.  

    * ERC20 contract address used for staking and rewards.  

### **Enum `Status` description**

* Status `Collecting`.  
  * Enum index value = `0`.  
  * During vault status `Collecting`, only the public methods below is allowed to be called:  
    * `deposit()`  
    * `exitWhileCollecting()` 

* Status `Staking`.  
  * Enum index value = `1`.  
  * During vault status `Staking`, only the public methods below is allowed to be called:
    * `exitWhileStaking()`.
  
* Status `Completed`.
  * Enum index value = `2`.
  * During vault status `Completed`, only the public methods below is allowed to be called:
    * `withdraw()`.  

### **Structs**

* **VaultInfo** 
  * `status`  
    * The status of the vault.
  
  * `stakingPeriod`
    * The length of stalking period in seconds.
  * `startTimestamp`
    * Unix timestamp when the staking started. 
  * `stopTimestamp`
    * Unix timestamp when the staking finished. 
  * `totalVaultShares`
    * The total amount of tokens staked in the vault.
  * `totalVaultRewards `
    * The total amount of tokens to be used as rewards for staking. 

* **RewardInfo**  

  * `lastRewardUpdateTimeStamp`
    * Is set every time the `pendingVaultRewards` is calulated.

  * `rewardRate`
    * The rate of reward.
    * ```rewardRate = totalVaultRewards / stakingPeriod```  
  * `pendingVaultRewards`
    * The accoumulated rewards that is ready to be released.
  * `claimedVaultRewards`
    * The rewards amount claimed.
  * `remainingVaultRewards`
    * The rewards amount remaining in the vault.

### **Custom errors**  

 _Custom errors are thrown if a function call has failed and is reverted._  

* `NotAuthorized()`.
  * Is thrown by the modifier `isStakeholder`.
* `NoZeroValues()`.
  * Is thrown by the modifier `noZeroValues`.
* `MaxStaked()`.
  * Is thrown by the modifier `limiter`.
* `NotCollecting()`.
  * Is thrown by the modifier `isCollecting`.
* `NotStaking()`.
  * Is thrown by the modifier `isStaking`.
* `NotCompleted()`.
  * Is thrown by the modifier `isCompleted`.
* `AddRewardsFailed()`.
  * Is thrown by the restricted method `addRewards(uint256 amount)`.
* `DepositFailed()`.
  * Is thrown by the public method `deposit(uint256 amount)`.
* `RewardFailed()`.
  * Is thrown by the public method `withdraw()`.
* `WithdrawFailed()`.
  * Is thrown by the public method `withdraw()`.

### **Methods**

#### **Public methods**

_Public state variables, and other non-state changing methods, consumes no gas when they are executed and run._

* **Public state variables.**

  * `token()`.  

    * Returns the staked erc20 address.  

  * `owner()`.  

    * Returns the owner address of this smart contract.  

  * `feeAddress()`.  

    * Returns the fee address that receives the withdrawal fees.  

  * `vault()`.  

    * Returns values from the `VaultInfo` struct.  

  * `withdrawFee()`.  

    * Returns fee percentage, `100` = `1%`.  
    
* **View methods.**

  * `getAccountErc20Balance(address account)`  

    * Returns the total user amount of the preset ERC20 token, available in the user account.  

    * The parameter `account` is the address to query.

  * `getAccountVaultBalance(address account)`.  

    * Returns the staked balance of the `account`.  

    * Parameter `account` is the address to query.

  * `getRewardInfo()`.  

    * Returns values from `RewardInfo`.

      * `lastRewardUpdateTimeStamp`.

      * `rewardRate`.
      * `pendingVaultRewards`.
      * `claimedVaultRewards`.
      * `remainingVaultRewards`.

* **State changing methods/ transactions.**

    * `deposit(uint256 amount)`.
      * Requires status `Collecting`.  

      * Allows a user to deposit and stake in the vault.  
        * Parameter `amount` is in Wei (_1 eth/erc20 = 1000000000000000000 Wei_).  
      
      * Requires the user to have `approved` TicketVault to spend the erc20 to deposit.  

      * Throws `depositFailed()` event if the transaction fails.  
      
    * `exitWhileCollecting()`.  
      * Requires status `Collecting`.  

      * Allows a stakeholder to withdraw their staked amount.
        * A `withdrawFee` is calculated from `withdrawAmount`, then paid to the fee address.  

        * Remaining `withdrawAmount` is transferred to the stakeholders account.   
    
    * `exitWhileStaking()`.  
      * Requires status `Staking`.  

      * Allows a stakeholder to exit their staked position.  
        * If during `withdrawPenaltyPeriod`, rewards are locked in vault. 

        * A `withdrawFee` is calculated from `withdrawAmount`, then paid to the fee address.  

        * Remaining `withdrawAmount` is sent to stakeholders account.  

    * `withdraw()`.
      * Requires status `Completed`.  

      * Allows a stakeholder to withdraw their stake, and accumulated rewards, without any withdraw fee.  

      * Emits the event `Withdraw(address indexed User, uint256 amount, uint256 rewards)` to the network.  

#### **Restricted methods**

  _onlyOwner restricted (only the owner address can call these methods)._

  * `setFeeAddress(address newFeeAddress)`.  
    * Assigns a new account to receive the withdrawal fees.  

      * The parameter `newFeeAddress` is the address to receive the withdrawal fees.  
      
  * `addRewards(uint256 amount)`.
    * Deposits the amount of ERC20 tokens to be distributed among the stakeholders as a reward for staking.  

      * Parameter `amount` is in Wei (_1 eth/erc20 = 1000000000000000000 Wei_).  

      * The `amount` is added to the existing `totalVaultRewards` variable in the `VaultInfo` struct.  

      * Throws a custom error `AddRewardsFailed()` if the transaction is reverted.

  * `startStaking()`.
    * Initiates the staking for the pre-set staking period.  

      * The Vault Status is changed from `Collecting` to `Staking`.  

      * Sets the vault `startTimestamp` to current `block.timestamp`.  

      * Sets the vault `stopTimestamp` by adding the vault `stakingPeriod` value to the `startTimestamp` value.  

      * Emits the event `StakingStarted`.  

  * `stopStaking()`.
    * Completes the staking period of this vault.  

      * Vault Status is changed from `Staking` to `Completed`.  

      * `remainingVaultRewards` is added to `pendingVaultRewards`, then reset to `0`.  

      * Emits the event `StakingCompleted()`.  

#### **Private methods**
_Private methods are only visible internal and can only be called by this contract._  

* `_deposit()`.  

  * Deposit funds to TicketVault.  

  * Is used by `addRewards()` and `deposit()` to pull funds from msg.sender, and into TicketVault.  

* `_withdraw()`.  

  * Withdraw funds from the TicketVault.  
  
  *  Is used by 
      * `withdraw()`, 
      * `exitWhileStaking()`,
      * `exitWhileCollecting()` 
    
      to withdraw the users stake from TicketVault.

* `_calculateUserReward(_totalUserShares)`.  
  
  * Calculates the pending user reward.  

  * Called by `exitWhileStaking()`, and `withdraw()` to calculate the user reward.  
  
  * Calculation:  

    ```js
    pendingUserReward = (pendingVaultRewards * ((_totalUserShares * 100) / totalVaultShares)) / 100;
    ```  

* `_calculatefee(_amount)`.  

  * Calculates the fee amount to pay to fee address.  

  * Called by `exitWhileStaking()`, and `exitWhileCollecting()` to calculate the fee amount.  

  * Calculation:  

    ```js
    feeAmount = _amount * withdrawFee / 10000;
    withdrawAmount = _amount - feeAmount; 
    ```