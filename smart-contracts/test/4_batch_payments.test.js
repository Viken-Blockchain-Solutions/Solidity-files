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

describe("BatchPayments", function () {

  let owner, spender, receiver1, receiver2, receiver3, receiver4, receiver5, receiver6, receiver7;
 
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, spender, receiver1, receiver2, receiver3, receiver4, receiver5, receiver6, receiver7] = await ethers.getSigners();
    
    // The bundled BN library is the same one web3 uses under the hood.
    this.value = new BN(2);
    this.total = new BN("10");
    this.sevenT = new BN("7000");
    this.sixT = new BN("6000");
    this.fiveT = new BN("5000");
    this.fourT = new BN("4000");
    this.threeT = new BN("3000");

    Token = await ethers.getContractFactory("TestERC20");
    Batch = await ethers.getContractFactory("BatchPayments");

    // deploy contracts
    token = await Token.deploy();
    batch = await Batch.deploy();

    await token.connect(spender).approve(batch.address, "10");
  });

  describe("Deployment :", function () {
    it("Should execute a batch transfer", async function () {
      const receipt = await batch.connect(spender).batchERC20Payment(token.address,
        [ receiver1, receiver2, receiver3, receiver4, receiver5 ], 
        [ this.value, this.value, this.value, this.value, this.value ]
      );
  
       // Event assertions can verify that the arguments are the expected ones.
      expectEvent(receipt, 'Transfer', { 
        from: spender,
        to: reciever1,
        value: this.value,
      });
    });
  });
});







/**
  describe("Contract Administration :", function () {
    it("Should let owner add rewardtokens to the vault", async function () {
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(totReward.toString());
      let VaultInfo = await vault.vault();

      expect(VaultInfo.totalVaultRewards.toString()).to.be.equal(totReward.toString());
    });
    it("Should allow the owner to start the staking", async function () { 
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(totReward.toString());
      await vault.connect(user4).deposit(fourT.toString());
      await vault.connect(user5).deposit(fiveT.toString());
      let startStaking = await vault.connect(owner).startStaking();
      expect(startStaking).to.emit(vault, "StakingStarted");

      let VaultInfo = await vault.vault();
      expect(VaultInfo.status).to.be.equal(1);
    })
  });

  describe("Vault Information :", function () {
    beforeEach(async function () {
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(totReward.toString());
    });
    it("Should contain the correct data about the vault", async function () {
      let VaultInfo = await vault.vault();
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

      expect(await vault.connect(user1).deposit(fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs(user1.address, fiveT.toString());

      expect(await vault.connect(user2).deposit(fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs(user2.address, fiveT.toString());
      
      const afterVaultBalance = await cent.balanceOf(vault.address);

      expect(afterVaultBalance.toString()).to.be.equal("2010000");
    });
    it("Should have the correct userInfo after a deposit", async function () {
      await vault.connect(user1).deposit(fiveT.toString());
      await vault.connect(user2).deposit(fiveT.toString());
      
      const userOneInfo = await vault.userBalance(user1.address);
      const userTwoInfo = await vault.userBalance(user2.address);
      
      expect(userOneInfo.toString()).to.be.equal(fiveT.toString());
      expect(userTwoInfo.toString()).to.be.equal(fiveT.toString());
    });
    it("Should have correct total amount of shares in the vault after deposit", async function () {
      await vault.connect(user1).deposit(fiveT.toString());
      await vault.connect(user2).deposit(fiveT.toString());
      
      let VaultInfo = await vault.vault();
      const vaultContractBalance = await cent.balanceOf(vault.address);
      expect(VaultInfo.totalVaultShares.toString()).to.be.equal("10000");
      expect(vaultContractBalance.toString()).to.be.equal("2010000");
    });
    it("Should let User1 exit position and pay 7% withdraw fees", async function () { 
      await vault.connect(user1).deposit(fiveT.toString());
      await vault.connect(user2).deposit(fiveT.toString());
      let feeBefore = await vault.connect(user1).balance(fee.address);
      let userBefore = await vault.connect(user1).userBalance(user1.address);
      
      expect(await vault.connect(user1).exitCollecting())
        .to.emit(vault, 'ExitWithFees');
      
      let feeAfter = await vault.connect(user1).balance(fee.address);
      let userAfter = await vault.connect(user1).userBalance(user1.address);

      expect(feeBefore.toString()).to.be.equal(userAfter.toString());
      expect(userBefore.toString()).to.be.equal("5000");
      expect(feeAfter.toString()).to.be.equal("350");
      expect(userAfter.toString()).to.be.equal(feeBefore.toString());
    }); 
    it("Should let the owner start the stakingpool :", async function () {
      await vault.connect(user1).deposit(fiveT.toString());
      await vault.connect(user2).deposit(fiveT.toString());
      
      expect(await vault.connect(owner).startStaking())
        .to.emit(vault, "StakingStarted");
  
      let VaultInfo = await vault.vault();
      expect(await VaultInfo.status).to.be.equal(1);
    });
  });

  describe("While Staking: Vault and Stakeholders", function () {
    beforeEach(async function () {
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(totReward.toString());

      //Users deposit tokens in vault.
      await vault.connect(user2).deposit(fiveT.toString());
      await vault.connect(user5).deposit(fiveT.toString());
      await vault.connect(owner).startStaking();

      let VaultInfo = await vault.vault();
      expect(VaultInfo.status).to.equal(1);
    });
    it("Should let a user exit staking position and pay the withdraw fee:", async function () {

      let feeBefore = await vault.connect(user5).balance(fee.address);
      let userBefore = await vault.connect(user5).userBalance(user5.address);
      
      expect(await vault.connect(user5).exitStaking())
        .to.emit(vault, 'ExitWithFees');
      
      let feeAfter = await vault.connect(user5).balance(fee.address);
      let userAfter = await vault.connect(user5).userBalance(user5.address);

      expect(feeBefore.toString()).to.be.equal(userAfter.toString());
      expect(userBefore.toString()).to.be.equal("5000");
      expect(feeAfter.toString()).to.be.equal("350");
      expect(userAfter.toString()).to.be.equal(feeBefore.toString());
    });
    it("Should have the correct metadata and values:", async function () {
      let Vault = await vault.vault();
      console.log(`
        VaultInfo :
              status                  :        ${Vault.status},
              totalVaultShares        :        ${Vault.totalVaultShares.toString()},
              startBlock              :        ${Vault.startTimestamp.toString()},
              stopBlock               :        ${Vault.stopTimestamp.toString()},   
              stakingPeriod           :        ${Vault.stakingPeriod.toString()},
              rewardRate              :        ${Vault.rewardRate.toString()},
              ratePerStakedToken      :        ${Vault.ratePerStakedToken.toString()},
              remainingRewards        :        ${Vault.remainingVaultRewards.toString()},
              totalVaultRewards       :        ${Vault.totalVaultRewards.toString()},
      `);
      });
    it("Should let owner stop the stakingpool", async function () {
      await vault.connect(owner).stopStaking();

      let VaultInfo = await vault.vault();
      console.log(`
        VaultInfo :
              status                  :        ${VaultInfo.status}
      `);
      //expect(await VaultInfo.status).to.be.equal(2);
    });
  });

  describe("While Completed: Vault and Stakeholders", function () {
    beforeEach(async function () {
      // approve vault to deposit tokens.
      await cent.connect(user1).approve(vault.address, fiveT.toString());
      await cent.connect(user2).approve(vault.address, fiveT.toString());

 
      // approve and initialize the vault.
      await cent.connect(owner).approve(vault.address, totReward.toString());
      await vault.connect(owner).addRewards(totReward.toString());

      //Users deposit tokens in vault.
      await vault.connect(user1).deposit(fiveT.toString());
      await vault.connect(user2).deposit(fiveT.toString());
      await vault.connect(owner).startStaking();

    });
    it("Should have the correct metadata and values:", async function () {
      await vault.connect(owner).stopStaking();
      let Vault = await vault.vault();
      console.log(`
        VaultInfo :
              status                  :        ${Vault.status},
              totalVaultShares        :        ${Vault.totalVaultShares.toString()},
              startBlock              :        ${Vault.startTimestamp.toString()},
              stopBlock               :        ${Vault.stopTimestamp.toString()},   
              stakingPeriod           :        ${Vault.stakingPeriod.toString()},
              rewardRate              :        ${Vault.rewardRate.toString()},
              ratePerStakedToken      :        ${Vault.ratePerStakedToken.toString()},
              remainingRewards        :        ${Vault.remainingVaultRewards.toString()},
              totalVaultRewards       :        ${Vault.totalVaultRewards.toString()},
      `);
      });
    it("Should let user1 withdraw position and rewards:", async function () {
      await vault.connect(owner).stopStaking();
      let balance = await vault.connect(user2).userBalance(user2.address);
      //let tx = await vault.connect(user1).withdraw();
      console.log(balance.toString());
      //console.log(tx);
    });
    });*/
