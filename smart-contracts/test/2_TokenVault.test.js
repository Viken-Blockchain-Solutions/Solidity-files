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

  let vault;
  let cent;
  let owner;
  let fee;
  let user1;
  let user1Balance;
  let user2;
  let user2Balance;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [owner, fee, user1, user2] = await ethers.getSigners();

    this.totReward = new BN("1500000000000000000000000");
    this.fiveT = new BN("5000000000000000000000");
    this.fourT = new BN("4000000000000000000000");
    CENTContract = await ethers.getContractFactory("CentaurifyToken");
    Contract = await ethers.getContractFactory("TicketVault");

    // deploy contracts
    cent = await CENTContract.deploy();
    vault = await Contract.deploy(fee.address);

    // Transfer 5000 tokens from owner to user1 || user2
    await cent.transfer(user1.address, this.fiveT.toString());
    await cent.transfer(user2.address, this.fiveT.toString());
    user1Balance = await cent.balanceOf(user1.address);
    user2Balance = await cent.balanceOf(user2.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner of vault contract", async function () {
      expect(await vault.owner()).to.equal(owner.address);
    });
    it("Should send 5000 test tokens to users 1 and 2's account", async function () {
      expect(user1Balance).to.equal(this.fiveT.toString());
      expect(user2Balance).to.equal(this.fiveT.toString());
    });
  });

  describe("Contract Administration", function () {
    it("Should let owner initiate a new vault", async function () {
      await cent
        .connect(owner)
        .approve(vault.address, this.totReward.toString());
  
      expect(
        await vault
        .connect(owner)
        // initializeVault(IERC20 _token, uint256 _id, uint256 _totVaultRewards)
        .initializeVault(cent.address, 0, this.totReward.toString())
      ).to.emit(vault, "VaultInitialized");
    });
  });

  describe("Vault Information", function () {
    beforeEach(async function () {
      await cent.connect(owner).approve(vault.address, this.totReward.toString());
      await vault.connect(owner).initializeVault(cent.address, 0, this.totReward.toString());
    });
    it("Should contain the correct data about the vault", async function () {
      const VaultInfo = await vault.vaultMapping(0);

      expect(VaultInfo.token).to.be.equal(cent.address);
      expect(VaultInfo.status).to.be.equal(0);
      expect(VaultInfo.rewardsPerBlock.toString()).to.be.equal('4000000000000000000');
      expect(VaultInfo.totalRewards).to.be.equal(this.totReward.toString());
    });
  });

  describe("Stake & stakeholders", function () {
    beforeEach(async function () {
      await cent.connect(owner).approve(vault.address, this.totReward.toString());
      await vault.connect(owner).initializeVault(cent.address, 0, this.totReward.toString());
    });
    it("Should let User1 and User2 stake 5000 tokens each", async function () {
      const beforeVaultBalance = await cent.balanceOf(vault.address);
      const beforeUser1Balance = await cent.balanceOf(user1.address);
      const beforeUser2Balance = await cent.balanceOf(user2.address);
      
      await cent.connect(user1).approve(vault.address, this.fiveT.toString());
      expect(await vault.connect(user1).deposit(0, this.fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs("0", this.fiveT.toString(), user1.address);
      
      await cent.connect(user2).approve(vault.address, this.fiveT.toString());
      expect(await vault.connect(user2).deposit(0, this.fiveT.toString()))
      .to.emit(vault, "Deposit")
        .withArgs("0", this.fiveT.toString(), user2.address);
      
      const afterVaultBalance = await cent.balanceOf(vault.address);
      const afterUser1Balance = await cent.balanceOf(user1.address);
      const afterUser2Balance = await cent.balanceOf(user2.address);
      
      expect(afterUser1Balance).to.be.equal(beforeUser1Balance.sub("5000000000000000000000"));
      expect(afterUser2Balance).to.be.equal(beforeUser2Balance.sub("5000000000000000000000"));
      expect(afterVaultBalance).to.be.equal(beforeVaultBalance.add("10000000000000000000000"));
    });
    it("Should have the correct userInfo after deposit", async function () {
      await cent.connect(user1).approve(vault.address, this.fiveT.toString());
      await cent.connect(user2).approve(vault.address, this.fiveT.toString());
      const userOneDeposit = await vault.connect(user1).deposit(0, this.fiveT.toString());
      const userTwoDeposit = await vault.connect(user2).deposit(0, this.fiveT.toString());
      
      const userOneInfo = await vault.usersMapping(0, user1.address);
      const userTwoInfo = await vault.usersMapping(0, user2.address);
      const userOneBalance = userOneInfo.totUserShares.toString();
      const userTwoBalance = userTwoInfo.totUserShares.toString();

      expect(userOneBalance).to.be.equal(this.fiveT.toString());
      expect(userTwoBalance).to.be.equal(this.fiveT.toString());
      expect(userOneInfo.user).to.be.equal(user1.address);
      expect(userTwoInfo.user).to.be.equal(user2.address);
      expect(userOneInfo.pendingRewards).to.be.equal(0);
      expect(userTwoInfo.pendingRewards).to.be.equal(0);
    });
    it("Should be correct total amount of shares in the vault", async function () {
      await cent.connect(user1).approve(vault.address, this.fiveT.toString());
      await cent.connect(user2).approve(vault.address, this.fiveT.toString());
      const userOneDeposit = await vault.connect(user1).deposit(0, this.fiveT.toString());
      const userTwoDeposit = await vault.connect(user2).deposit(0, this.fiveT.toString());
      
      const VaultInfo = await vault.vaultMapping(0);
      const vaultContractBalance = await cent.balanceOf(vault.address);

      expect(VaultInfo.totalVaultShares.toString()).to.be.equal("10000000000000000000000");
      expect(vaultContractBalance.toString()).to.be.equal("1510000000000000000000000");
    });
    it("Should let User1 withdraw 4000 tokens", async function () {
      await cent.connect(user1).approve(vault.address, this.fiveT.toString());
      await cent.connect(user2).approve(vault.address, this.fiveT.toString());
      const userOneDeposit = await vault.connect(user1).deposit(0, this.fiveT.toString());
      const userTwoDeposit = await vault.connect(user2).deposit(0, this.fiveT.toString());
      await userOneDeposit;
      await userTwoDeposit;

      const beforeVaultBalance = await cent.balanceOf(vault.address);
      const userOneInfo = await vault.usersMapping(0, user1.address);
      const userTwoInfo = await vault.usersMapping(0, user2.address);
      const userOneBeforeBalance = userOneInfo.totUserShares.toString();
      const userTwoBeforeBalance = userTwoInfo.totUserShares.toString();
      console.log('Vault before Shares:', beforeVaultBalance.toString());
      console.log('User One before Shares:', userOneBeforeBalance);
      console.log('User Two before Shares:', userTwoBeforeBalance);
     
      expect(await vault.connect(user1).withdraw(0, this.fourT.toString()))
      .to.emit(vault, 'Withdraw')
        .withArgs(0, this.fourT.toString(), user1.address);

      const afterVaultBalance = await cent.balanceOf(vault.address);
      const userOneAfterInfo = await vault.usersMapping(0, user1.address);
      const userTwoAfterInfo = await vault.usersMapping(0, user2.address);
      const userOneAfterBalance = userOneAfterInfo.totUserShares.toString();
      const userTwoAfterBalance = userTwoAfterInfo.totUserShares.toString();
  
      console.log('Vault after Shares:', afterVaultBalance.toString());
      console.log('User One after Shares:', userOneAfterBalance);
      console.log('User Two after Shares:', userTwoAfterBalance);

     // expect(userOneAfterBalance).to.be.equal(userOneBeforeBalance.toNumber().add(this.fourT.toString()));
      expect(userTwoAfterBalance).to.be.equal(userTwoBeforeBalance);
      expect(afterVaultBalance).to.be.equal(userOneAfterBalance.add(userTwoAfterBalance));
    });

  });
});