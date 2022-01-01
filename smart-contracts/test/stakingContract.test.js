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
  let stakingContract;
  let staking;
  let testERC20;
  let owner;
  let addr1;
  let addr1Balance;
  let addr2;
  let addr2Balance;
  let addrs;  

  before(async function () {
    // Get the ContractFactory and Signers here.
    testERC20Contract = await ethers.getContractFactory("testERC20");
    stakingContract = await ethers.getContractFactory("StakingContract");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    staking = await stakingContract.deploy();
    testERC20 = await testERC20Contract.deploy();

    // Transfer 50 tokens from owner to addr1
    await testERC20.transfer(addr1.address, 5000);
    await testERC20.transfer(addr2.address, 5000);
    addr1Balance = await testERC20.balanceOf(addr1.address);
    addr2Balance = await testERC20.balanceOf(addr2.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner of staking contract", async function () {
      expect(await staking.owner()).to.equal(owner.address);
    });
    it("Should have transfered tokens to accounts for testing", async function () {
      expect(addr1Balance).to.equal(5000);
      expect(addr2Balance).to.equal(5000);
    });
  });

  describe("Contract Administration", function () {
    it("Should let the owner, set the staking token", async function () {
      await staking.setToken(testERC20.address);
      const name = await testERC20.name();
      const tokenName = await staking.stakedERC20();
      expect(tokenName).to.equal(name);
    });
  });

  describe("Stakeholders and staking", function () {
    before(async function () {
      await staking.setToken(testERC20.address);
      const tokenName = await staking.stakedERC20();
      console.log("Staked token: %d", tokenName);
    })
  })

})
