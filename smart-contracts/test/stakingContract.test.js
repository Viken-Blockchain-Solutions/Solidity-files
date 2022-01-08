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
  let user1;
  let user1Balance;
  let user2;
  let user2Balance; 

  before(async function () {
    // Get the ContractFactory and Signers here.
    [owner, user1, user2] = await ethers.getSigners();
    
    testERC20Contract = await ethers.getContractFactory("testERC20");
    Contract = await ethers.getContractFactory("StakingContract");

    testERC20 = await testERC20Contract.deploy();
    staking = await Contract.deploy(testERC20.address);

    // Transfer 50 tokens from owner to user1
    await testERC20.transfer(user1.address, 5000);
    await testERC20.transfer(user2.address, 5000);
    user1Balance = await testERC20.balanceOf(user1.address);
    user2Balance = await testERC20.balanceOf(user2.address);
  });

  describe("Deployment", function () {

    it("Should set the right owner of staking contract", async function () {
      expect(await staking.owner()).to.equal(owner.address);
    });
    it("Should be 5000 test tokens on user1 and user2", async function () {
      expect(user1Balance).to.equal(5000);
      expect(user2Balance).to.equal(5000);
    });
  });

  describe("Contract Administration", function () {
    it("Should habe set the correct staking token", async function () {
      const name = await testERC20.name();
      expect("testERC20").to.equal(name);
    });
  });

  describe("Staking & stakeholders", function () {
    beforeEach(async function () {
      await testERC20.connect(user1).approve(staking.address, 1000);
    });

    it("Should let user1 stake 100 tokens", async function () {
      expect(
        await staking.connect(user1).addStake(1000))
        .to.emit(staking, "StakedInVault");
    });
  });
})
