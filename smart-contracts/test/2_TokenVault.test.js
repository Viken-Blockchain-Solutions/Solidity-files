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
  let user1Balance, user2Balance, user3Balance, user4Balance, user5Balance, user6Balance, user7Balance;
  let totReward, sevenT, sixT, fiveT, fourT, threeT;
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, fee, user1, user2, user3, user4, user5, user6, user7] = await ethers.getSigners();

    totReward = new BN("2000000000000000000000000"); // 2 000 000
    sevenT = new BN("700000000000000000000000"); // 700 000
    sixT = new BN("60000000000000000000000"); // 60 000
    fiveT = new BN("50000000000000000000000"); // 50 000
    fourT = new BN("4000000000000000000000"); // 4000
    threeT = new BN("300000000000000000000"); // 300

    CENTContract = await ethers.getContractFactory("CentaurifyToken");
    Contract = await ethers.getContractFactory("TicketVault");

    // deploy contracts
    cent = await CENTContract.deploy();
    vault = await Contract.deploy(cent.address);

    // Transfer tokens to test users
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

    await cent.connect(user1).approve(vault.address, fiveT.toString());
    await cent.connect(user2).approve(vault.address, fiveT.toString());
    await cent.connect(user3).approve(vault.address, threeT.toString());
    await cent.connect(user4).approve(vault.address, fourT.toString());
    await cent.connect(user5).approve(vault.address, fiveT.toString());
    await cent.connect(user6).approve(vault.address, sixT.toString());
    await cent.connect(user7).approve(vault.address, sevenT.toString());
  });

  describe("Deployment :", function () {
    it("Should set the right owner, admin and fee address of vault contract", async function () {
      expect(await vault.owner()).to.equal(owner.address);
      expect(await vault.feeAddress()).to.equal(fee.address);
    });
  });

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
    it("Should let User1 and User2 deposit tokens", async function () {
      const beforeVaultBalance = await cent.balanceOf(vault.address);

      expect(await vault.connect(user1).deposit(fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs(user1.address, fiveT.toString());

      expect(await vault.connect(user2).deposit(fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs(user2.address, fiveT.toString());
      
      const afterVaultBalance = await cent.balanceOf(vault.address);

      expect(afterVaultBalance.toString()).to.be.equal("2100000000000000000000000");
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
      expect(VaultInfo.totalVaultShares.toString()).to.be.equal("100000000000000000000000");
      expect(vaultContractBalance.toString()).to.be.equal("2100000000000000000000000");
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
      expect(userBefore.toString()).to.be.equal("50000000000000000000000");
      expect(feeAfter.toString()).to.be.equal("3500000000000000000000");
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
      expect(userBefore.toString()).to.be.equal("50000000000000000000000");
      expect(feeAfter.toString()).to.be.equal("3500000000000000000000");
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
              total Vault shares      :        ${VaultInfo.totalVaultShares}
              status                  :        ${VaultInfo.status}
              RewardRate              :        ${VaultInfo.rewardRate}
              rate per staked token   :        ${VaultInfo.ratePerStakedToken}
      `);
      expect(await VaultInfo.status).to.be.equal(2);
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
      await vault.connect(user6).deposit(sixT.toString());
      await vault.connect(user7).deposit(sevenT.toString());
      await vault.connect(owner).startStaking();

    });
    it("Should let user1 withdraw position and rewards:", async function () {
      await vault.connect(owner).stopStaking();
      await expect(vault.connect(user2).withdraw())
        .to.emit(vault, "Withdraw");
    });
    it("Should have the correct metadata and values:", async function () {
      await vault.connect(owner).stopStaking();
      vault.connect(user1).withdraw();
      vault.connect(user6).withdraw();

      let Vault = await vault.vault();
      console.log(`
        VaultInfo :
              status                  :        ${Vault.status},
              totalVaultShares        :        ${Vault.totalVaultShares.toString() / 1e18},
              startBlock              :        ${Vault.startTimestamp.toString()},
              stopBlock               :        ${Vault.stopTimestamp.toString()},   
              stakingPeriod           :        ${Vault.stakingPeriod.toString()},
              rewardRate              :        ${Vault.rewardRate.toString() / 1e18},
              ratePerStakedToken      :        ${Vault.ratePerStakedToken.toString()},
              remainingRewards        :        ${Vault.remainingVaultRewards.toString()},
              claimedVaultRewards     :        ${Vault.claimedVaultRewards.toString()},
              totalVaultRewards       :        ${Vault.totalVaultRewards.toString()},
      `);
    });
  });
});