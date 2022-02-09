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

  let vault, cent, owner, admin, fee, user1, user2, user3, user4, user5, user6;
  let user7, user8, user9, user10;
  
  let user1Balance, user2Balance;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, admin, fee, user1, user2, user3, user4, user5, user6, user7] = await ethers.getSigners();

    this.rewardsPerBlock = new BN("3381230700000000000");
    this.totReward = new BN("2000000000000000000000000");
    this.sevenT = new BN("70000000000000000000000");
    this.sixT = new BN("60000000000000000000000");
    this.fiveT = new BN("50000000000000000000000");
    this.fourT = new BN("40000000000000000000000");
    this.threeT = new BN("30000000000000000000000");

    CENTContract = await ethers.getContractFactory("CentaurifyToken");
    Contract = await ethers.getContractFactory("TicketVault");

    // deploy contracts
    cent = await CENTContract.deploy();
    vault = await Contract.deploy(cent.address, admin.address, fee.address);

    // Transfer 5000 tokens from owner to user1 || user2
    await cent.transfer(user1.address, this.fiveT.toString());
    await cent.transfer(user2.address, this.fiveT.toString());
    user1Balance = await cent.balanceOf(user1.address);
    user2Balance = await cent.balanceOf(user2.address);
  });

  describe("Deployment :", function () {
    it("Should set the right owner, admin and fee address of vault contract", async function () {
      expect(await vault.owner()).to.equal(owner.address);
      expect(await vault.admin()).to.equal(admin.address);
      expect(await vault.feeAddress()).to.equal(fee.address);

    });
    it("Should send 5000 test tokens to users 1 and 2's account", async function () {
      expect(user1Balance).to.equal(this.fiveT.toString());
      expect(user2Balance).to.equal(this.fiveT.toString());
    });
  });

  describe("Contract Administration :", function () {
    it("Should let owner initiate a new vault", async function () {
      await cent
        .connect(owner)
        .approve(vault.address, this.totReward.toString());
  
      expect(
        await vault
        .connect(owner)
        // initializeVault(uint256 rewardsPerBlock, uint256 _totVaultRewards)
        .initializeVault(this.rewardsPerBlock.toString(), this.totReward.toString())
      ).to.emit(vault, "VaultInitialized");
    });
  });

  describe("Vault Information :", function () {
    beforeEach(async function () {
      await cent.connect(owner).approve(vault.address, this.totReward.toString());
      await vault.connect(owner).initializeVault(
        this.rewardsPerBlock.toString(),
        this.totReward.toString()
      );
    });
    it("Should contain the correct data about the vault", async function () {
      const VaultInfo = await vault.vault();
      const token = await vault.token();

      expect(token).to.be.equal(cent.address);
      expect(VaultInfo.status).to.be.equal(0);
      expect(VaultInfo.rewardsPerBlock.toString()).to.be.equal(this.rewardsPerBlock.toString());
      expect(VaultInfo.remainingRewards.toString()).to.be.equal(this.totReward.toString());
      expect(VaultInfo.totalVaultRewards.toString()).to.be.equal(this.totReward.toString());
    });
  });

  describe("While Collecting: Vault & Stakeholders.", function () {
    beforeEach(async function () {
      await cent.connect(owner).approve(vault.address, this.totReward.toString());
      await vault.connect(owner).initializeVault(
        this.rewardsPerBlock.toString(),
        this.totReward.toString()
      );
    });
    it("Should let User1 and User2 deposit 5000 tokens each", async function () {
      const beforeVaultBalance = await cent.balanceOf(vault.address);
      const beforeUser1Balance = await cent.balanceOf(user1.address);
      const beforeUser2Balance = await cent.balanceOf(user2.address);
      
      await cent.connect(user1).approve(vault.address, this.fiveT.toString());
      expect(await vault.connect(user1).deposit(this.fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs(this.fiveT.toString(), user1.address);
      
      await cent.connect(user2).approve(vault.address, this.fiveT.toString());
      expect(await vault.connect(user2).deposit(this.fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs(this.fiveT.toString(), user2.address);
      
      const afterVaultBalance = await cent.balanceOf(vault.address);
      const afterUser1Balance = await cent.balanceOf(user1.address);
      const afterUser2Balance = await cent.balanceOf(user2.address);
      
      expect(afterUser1Balance).to.be.equal(beforeUser1Balance.sub("50000000000000000000000"));
      expect(afterUser2Balance).to.be.equal(beforeUser2Balance.sub("50000000000000000000000"));
      expect(afterVaultBalance).to.be.equal(beforeVaultBalance.add("100000000000000000000000"));
    });
    it("Should have the correct userInfo after deposit", async function () {
      await cent.connect(user1).approve(vault.address, this.fiveT.toString());
      await cent.connect(user2).approve(vault.address, this.fiveT.toString());
      await vault.connect(user1).deposit(this.fiveT.toString());
      await vault.connect(user2).deposit(this.fiveT.toString());
      
      const userOneInfo = await vault.users(user1.address);
      const userTwoInfo = await vault.users(user2.address);
      const userOneBalance = userOneInfo.totUserShares.toString();
      const userTwoBalance = userTwoInfo.totUserShares.toString();

      expect(userOneBalance).to.be.equal(this.fiveT.toString());
      expect(userTwoBalance).to.be.equal(this.fiveT.toString());
      expect(userOneInfo.user).to.be.equal(user1.address);
      expect(userTwoInfo.user).to.be.equal(user2.address);
      expect(userOneInfo.pendingRewards).to.be.equal(0);
      expect(userTwoInfo.pendingRewards).to.be.equal(0);
    });
    it("Should have correct total amount of shares in the vault after deposit", async function () {
      await cent.connect(user1).approve(vault.address, this.fiveT.toString());
      await cent.connect(user2).approve(vault.address, this.fiveT.toString());
      await vault.connect(user1).deposit(this.fiveT.toString());
      await vault.connect(user2).deposit(this.fiveT.toString());
      
      const VaultInfo = await vault.vault();
      const vaultContractBalance = await cent.balanceOf(vault.address);

      expect(VaultInfo.totalVaultShares.toString()).to.be.equal("100000000000000000000000");
      expect(vaultContractBalance).to.be.equal("2100000000000000000000000");
    });
    it("Should let User1 withdraw 40000 tokens", async function () {
      await cent.connect(user1).approve(vault.address, this.fiveT.toString());
      await cent.connect(user2).approve(vault.address, this.fiveT.toString());
      await vault.connect(user1).deposit(this.fiveT.toString());
      await vault.connect(user2).deposit(this.fiveT.toString());
  
      // get vault and user balances before withdraw.
      const beforeVaultBalance = await cent.balanceOf(vault.address);
      const userOneInfo = await vault.users(user1.address);
      const userTwoInfo = await vault.users(user2.address);
      const userOneBeforeShares = userOneInfo.totUserShares;
      const userTwoBeforeShares = userTwoInfo.totUserShares;

      // execute a withdraw from user 1.
      expect(await vault.connect(user1).withdraw(this.fourT.toString()))
      .to.emit(vault, 'EarlyWithdraw')
        .withArgs(this.fourT.toString(), user1.address);

      // get vault and user balances After withdraw.
      const afterVaultBalance = await cent.balanceOf(vault.address);
      const userOneAfterInfo = await vault.users(user1.address);
      const userTwoAfterInfo = await vault.users(user2.address);
      const userOneAfterShares = userOneAfterInfo.totUserShares;
      const userTwoAfterShares = userTwoAfterInfo.totUserShares;

      expect(userOneAfterShares.toString()).to.be.equal("10000000000000000000000");
      expect(userTwoAfterShares).to.be.equal(userTwoBeforeShares);
      expect(beforeVaultBalance.toString()).to.be.equal("2100000000000000000000000");
      expect(afterVaultBalance.toString()).to.be.equal("2060000000000000000000000");
    });

  });

  describe("While Started: Vault and Stakeholders", function () {

    beforeEach(async function () {
      // transfer tokens to testusers.
      await cent.transfer(user3.address, this.threeT.toString());
      await cent.transfer(user4.address, this.fourT.toString());
      await cent.transfer(user5.address, this.fiveT.toString());
      await cent.transfer(user6.address, this.sixT.toString());
      await cent.transfer(user7.address, this.sevenT.toString());
      
      // approve vault to deposit tokens.
      await cent.connect(user1).approve(vault.address, this.fiveT.toString());
      await cent.connect(user2).approve(vault.address, this.fiveT.toString());
      await cent.connect(user3).approve(vault.address, this.threeT.toString());
      await cent.connect(user4).approve(vault.address, this.fourT.toString());
      await cent.connect(user5).approve(vault.address, this.fiveT.toString());
      await cent.connect(user6).approve(vault.address, this.sixT.toString());
      await cent.connect(user7).approve(vault.address, this.sevenT.toString());
      
      // approve and initialize the vault.
      await cent.connect(owner).approve(vault.address, this.totReward.toString());
      await vault.connect(owner).initializeVault(
        this.rewardsPerBlock.toString(),
        this.totReward.toString()
      );

      //Users deposit tokens in vault.
      await vault.connect(user1).deposit(this.fiveT.toString());
      await vault.connect(user2).deposit(this.fiveT.toString());
      await vault.connect(user3).deposit(this.threeT.toString());
      await vault.connect(user4).deposit(this.fourT.toString());
      await vault.connect(user5).deposit(this.fiveT.toString());
      await vault.connect(user6).deposit(this.sixT.toString());
      await vault.connect(user7).deposit(this.sevenT.toString());

    });

    it("Should let the owner set to status Started :", async function () {
      expect(await vault.connect(owner).startVault(1500))
        .to.emit(vault, "VaultStarted")
      
      await vault.connect(owner).updateVault();
      
      const VaultInfo = await vault.vault();
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