const { expect } = require("chai");
// `describe` receives the name of a section of your test suite, and a callback.
// The callback must define the tests of that section. This callback can't be
// an async function.
describe("Staking contract", function () {
  // Mocha has four functions that let you hook into the the test runner's
  // lifecyle. These are: `before`, `beforeEach`, `after`, `afterEach`.

  // They're very useful to setup the environment for tests, and to clean it
  // up after they run.

  // A common pattern is to declare some variables, and assign them in the
  // `before` and `beforeEach` callbacks.
  let testERC20Contract;
  let staking;
  let testERC20;
  let owner;
  let dev;
  let user1;
  let user1Balance;
  let user2;
  let user2Balance;

  before(async function () {
    // Get the ContractFactory and Signers here.
    [owner, dev, user1, user2] = await ethers.getSigners();

    testERC20Contract = await ethers.getContractFactory("testERC20");
    Contract = await ethers.getContractFactory("SingleStaking");

    testERC20 = await testERC20Contract.deploy();

    // constructor arguments (address _dev, uint256 _centPerBlock) {
    staking = await Contract.deploy(dev.address, 10);

    // Transfer 5000 tokens from owner to user1 || user2
    await testERC20.transfer(user1.address, 5000);
    await testERC20.transfer(user2.address, 5000);
    user1Balance = await testERC20.balanceOf(user1.address);
    user2Balance = await testERC20.balanceOf(user2.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner of staking contract", async function () {
      expect(await staking.owner()).to.equal(owner.address);
    });
    it("Should sennd 5000 test tokens to users 1 and 2´s account", async function () {
      expect(user1Balance).to.equal(5000);
      expect(user2Balance).to.equal(5000);
    });
  });

  describe("Contract Administration", function () {
    it("Should let owner initiate a new pool", async function () {
      await testERC20
        .connect(owner)
        .approve(staking.address, 1500000);
  
      expect(
        await staking
        .connect(owner)
        // initiatePool(uint256 _allocPoint, IERC20 _lpToken, uint256 _totRewardAmount)
        .initiatePool(1000, testERC20.address, 1500000)
      ).to.emit(staking, "PoolInitiated");
  });
});
  describe("Staking & stakeholders", function () {
    it("Should let user2 stake 5000 tokens", async function () {
      const beforeUser2Balance = await testERC20.balanceOf(user2.address);
      await testERC20.connect(user2).approve(staking.address, 500);
      
      expect(await staking.connect(user2).addStake(0, 500))
        .to.emit(staking, "StakedToPool")
        .withArgs(user2.address, 0, 500);
      
      const afterUser2Balance = await testERC20.balanceOf(user2.address);
      expect(afterUser2Balance).to.be.equal(beforeUser2Balance.sub(500))
    });
  });
});
