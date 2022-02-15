// Apply configuration
require('@openzeppelin/test-helpers/configure')({
  provider: 'http://localhost:8545',
});

const { expect } = require("chai");
const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

describe("TicketVault", function () {

  let vault, cent, owner, fee, user1, user2, user3, user4, user5, user6, user7;
  let feeAmount, withdrawAmount;
  let user1Balance, user2Balance, user3Balance, user4Balance, user5Balance, user6Balance, user7Balance;
  let totReward, sevenT, sixT, fiveT, fourT, threeT;
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, fee, user1, user2, user3, user4, user5, user6, user7] = await ethers.getSigners();

    //const rewardsPerBlock = new BN("3381230700000000000");
    totReward = new BN("2000000000000000000000000");
    sevenT = new BN("70000000000000000000000");
    sixT = new BN("60000000000000000000000");
    fiveT = new BN("50000000000000000000000");
    fourT = new BN("40000000000000000000000");
    threeT = new BN("30000000000000000000000");

    CENTContract = await ethers.getContractFactory("CentaurifyToken");
    Contract = await ethers.getContractFactory("TicketVault");

    // deploy contracts
    cent = await CENTContract.deploy();
    vault = await Contract.deploy(cent.address, fee.address);

    // Transfer 5000 tokens from owner to user1 || user2
    await cent.transfer(user1.address, fiveT.toString());
    await cent.transfer(user2.address, fiveT.toString());
    await cent.transfer(user3.address, threeT.toString());
    await cent.transfer(user4.address, fourT.toString());
    await cent.transfer(user5.address, fiveT.toString());
    await cent.transfer(user6.address, sixT.toString());
    await cent.transfer(user7.address, sevenT.toString());
    user1Balance = await cent.balanceOf(user1.address);
    user2Balance = await cent.balanceOf(user2.address);
    user3Balance = await cent.balanceOf(user3.address);
    user4Balance = await cent.balanceOf(user4.address);
    user5Balance = await cent.balanceOf(user5.address);
    user6Balance = await cent.balanceOf(user6.address);
    user7Balance = await cent.balanceOf(user7.address);
  });

  describe("Deployment :", function () {
    it("Should set the right owner, admin and fee address of vault contract", async function () {
      expect(await vault.owner()).to.equal(owner.address);
      expect(await vault.feeAddress()).to.equal(fee.address);
    });
    it("Should send 5000 test tokens to users 1 and 2's account", async function () {
      expect(user1Balance).to.equal(fiveT.toString());
      expect(user2Balance).to.equal(fiveT.toString());
      expect(user4Balance).to.equal(fourT.toString());
      expect(user7Balance).to.equal(sevenT.toString());
    });
  });

  describe("Contract Administration :", function () {
    it("Should let owner add rewardtokens to the vault", async function () {
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(totReward.toString());
      const VaultInfo = await vault.vault();

      expect(VaultInfo.totalVaultRewards.toString()).to.be.equal(totReward.toString());
    });
    it("Should allow the owner to start the staking", async function () { 
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(totReward.toString());
     // await vault.connect(owner).startStaking();
    })
  });

  describe("Vault Information :", function () {
    beforeEach(async function () {
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(totReward.toString());
    });
    it("Should contain the correct data about the vault", async function () {
      const VaultInfo = await vault.vault();
      expect(VaultInfo.status).to.be.equal(0);
      expect(VaultInfo.stakingPeriod.toString()).to.be.equal("7862400");
      expect(VaultInfo.remainingVaultRewards.toString()).to.be.equal(totReward.toString());
      expect(VaultInfo.totalVaultRewards.toString()).to.be.equal(totReward.toString());
    });
  });

  describe("While Collecting :", function () {
    beforeEach(async function () {
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(totReward.toString());
    });
    it("Should let User1 and User2 deposit 50000 tokens", async function () {
      const beforeVaultBalance = await cent.balanceOf(vault.address);
      const beforeUser1Balance = await cent.balanceOf(user1.address);
      const beforeUser2Balance = await cent.balanceOf(user2.address);
      
      await cent.connect(user1).approve(vault.address, fiveT.toString());
      expect(await vault.connect(user1).deposit(fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs(user1.address, fiveT.toString());
      
      await cent.connect(user2).approve(vault.address, fiveT.toString());
      expect(await vault.connect(user2).deposit(fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs(user2.address, fiveT.toString());
      
      const afterVaultBalance = await cent.balanceOf(vault.address);
      const afterUser1Balance = await cent.balanceOf(user1.address);
      const afterUser2Balance = await cent.balanceOf(user2.address);
      
      expect(afterUser1Balance).to.be.equal(beforeUser1Balance.sub("50000000000000000000000"));
      expect(afterUser2Balance).to.be.equal(beforeUser2Balance.sub("50000000000000000000000"));
      expect(afterVaultBalance).to.be.equal(beforeVaultBalance.add("100000000000000000000000"));
    });
    it("Should have the correct userInfo after a deposit", async function () {
      await cent.connect(user1).approve(vault.address, fiveT.toString());
      await cent.connect(user2).approve(vault.address, fiveT.toString());
      await vault.connect(user1).deposit(fiveT.toString());
      await vault.connect(user2).deposit(fiveT.toString());
      
      const userOneInfo = await vault.userBalance(user1.address);
      const userTwoInfo = await vault.userBalance(user2.address);
      
      expect(userOneInfo.toString()).to.be.equal(fiveT.toString());
      expect(userTwoInfo.toString()).to.be.equal(fiveT.toString());
    });
    it("Should have correct total amount of shares in the vault after deposit", async function () {
      await cent.connect(user1).approve(vault.address, fiveT.toString());
      await cent.connect(user2).approve(vault.address, fiveT.toString());
      await vault.connect(user1).deposit(fiveT.toString());
      await vault.connect(user2).deposit(fiveT.toString());
      
      const VaultInfo = await vault.vault();
      const vaultContractBalance = await cent.balanceOf(vault.address);

      expect(VaultInfo.totalVaultShares.toString()).to.be.equal("100000000000000000000000");
      expect(vaultContractBalance).to.be.equal("2100000000000000000000000");
    });
    it("Should let User1 withdraw 40000 tokens and pay 7% withdraw fees", async function () { 
      feeAmount = new BN("28000000000000000000000");
      withdrawAmount = new BN("37200000000000000000000");

      await cent.connect(user1).approve(vault.address, fiveT.toString());
      await cent.connect(user2).approve(vault.address, fiveT.toString());
      await vault.connect(user1).deposit(fiveT.toString());
      await vault.connect(user2).deposit(fiveT.toString());
  
      // vault balance
      const beforeVaultBalance = await cent.balanceOf(vault.address);

      // fee balance
      const feeBeforeBalance = await cent.balanceOf(fee.address);
    
      // user balance
      const userTwoInfo = await vault.userBalance(user2.address);
    
      // execute a withdraw from user 1.
      expect(await vault.connect(user1).exitCollecting())
        .to.emit(vault, 'ExitWithFee')
        .withArgs(user1.address, feeAmount, withdrawAmount)
      // get vault, fee and user balances after user withdraw.
      const afterVaultBalance = await cent.balanceOf(vault.address);

      // fee balance
      const feeAfterBalance = await cent.balanceOf(fee.address);
      console.log(feeAfterBalance.toString());
      // user balance
      const userOneAfterInfo = await vault.users(user1.address);
      const userTwoAfterInfo = await vault.users(user2.address);
      


      expect(userOneAfterInfo.toString()).to.be.equal("10000000000000000000000");
      expect(userTwoAfterInfo).to.be.equal(userTwoBeforeInfo);
      expect(beforeVaultBalance.toString()).to.be.equal("2100000000000000000000000");
      expect(afterVaultBalance.toString()).to.be.equal("2060000000000000000000000");
    });
    it("Should let the owner start the vault rewards :", async function () {
      expect(await vault.connect(owner).startVault(1500))
      .to.emit(vault, "VaultStarted");
  
      const VaultInfo = await vault.vault();
      expect(await VaultInfo.status).to.be.equal(1);
    });
  });

  describe("While Started: Vault and Stakeholders", function () {
    beforeEach(async function () {
      // transfer tokens to testusers.
      await cent.transfer(user3.address, threeT.toString());
      await cent.transfer(user4.address, fourT.toString());
      await cent.transfer(user5.address, fiveT.toString());
      await cent.transfer(user6.address, sixT.toString());
      await cent.transfer(user7.address, sevenT.toString());

      
      // approve vault to deposit tokens.
      await cent.connect(user1).approve(vault.address, fiveT.toString());
      await cent.connect(user2).approve(vault.address, fiveT.toString());
      await cent.connect(user3).approve(vault.address, threeT.toString());
      await cent.connect(user4).approve(vault.address, fourT.toString());
      await cent.connect(user5).approve(vault.address, fiveT.toString());
      await cent.connect(user6).approve(vault.address, sixT.toString());
      await cent.connect(user7).approve(vault.address, sevenT.toString());
 
      
      // approve and initialize the vault.
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(rewardsPerBlock.toString());

      //Users deposit tokens in vault.
      await vault.connect(user1).deposit(fiveT.toString());
      await vault.connect(user2).deposit(fiveT.toString());
      await vault.connect(user3).deposit(threeT.toString());
      await vault.connect(user4).deposit(fourT.toString());
      await vault.connect(user5).deposit(fiveT.toString());
      await vault.connect(user6).deposit(sixT.toString());
      await vault.connect(user7).deposit(sevenT.toString());
      await vault.connect(owner).startVault(1500);
      VaultInfo = await vault.vault();
      expect(VaultInfo.status).to.equal(1);
    });
 
    it("Should let a user claim their pending rewards :", async function () {
      const userTwoBeforeBalance = await cent.balanceOf(user2.address);
      expect(await vault.connect(user2).claim())
        .to.emit(vault, "Withdraw");

      const userTwoAfterBalance = await cent.balanceOf(user2.address);
      console.log(userTwoBeforeBalance.toString());
      console.log(userTwoAfterBalance.toString());
    

    


      /* 
      await vault.connect(user7).claim();
      await vault.connect(user6).claim();
      await vault.connect(user5).claim();
      await vault.connect(user1).claim();
      await vault.connect(user4).claim();
      await vault.connect(user3).claim();

      console.log(await vault.connect(user8).getUserInfo());
      console.log(await vault.connect(user7).getUserInfo());
      console.log(await vault.connect(user6).getUserInfo());
      console.log(await vault.connect(user5).getUserInfo());
      console.log(await vault.connect(user1).getUserInfo());
      console.log(await vault.connect(user4).getUserInfo());
      console.log(await vault.connect(user2).getUserInfo());
      console.log(await vault.connect(user3).getUserInfo()); 
  
      await vault.connect(owner).updateVault();
      */
     
    VaultInfo = await vault.vault();
     console.log(`
       VaultInfo :
             status                  :        ${VaultInfo.status},
             totalVaultShares        :        ${VaultInfo.totalVaultShares.toString()},
             startBlock              :        ${VaultInfo.startBlock.toString()},
             stopBlock               :        ${VaultInfo.stopBlock.toString()},   
             rewardsPerBlock         :        ${VaultInfo.rewardsPerBlock.toString()},
             lastRewardBlock         :        ${VaultInfo.lastRewardBlock.toString()},
             pendingRewards          :        ${VaultInfo.pendingRewards.toString()},
             remainingRewards        :        ${VaultInfo.remainingRewards.toString()},
             totalVaultRewards       :        ${VaultInfo.totalVaultRewards.toString()},
             withdrawFeePeriod       :        ${VaultInfo.withdrawFeePeriod.toString()},
             withdrawPenaltyPeriod   :        ${VaultInfo.withdrawPenaltyPeriod.toString()}
     `);
    });
    });
});