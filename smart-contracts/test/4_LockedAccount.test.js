require('@openzeppelin/test-helpers/configure')({
    provider: 'http://localhost:8545',
});
  
const { expect } = require("chai");
const { BN } = require('@openzeppelin/test-helpers');


describe("LockedAccount", function () {
  
  let owner, whitelisted, whitelisted_1, whitelisted_2, whitelisted_3, whitelisted_4;


  before(async function () {
    // Get the ContractFactory and Signers here.
    [ owner, whitelisted, whitelisted_1, whitelisted_2, whitelisted_3, whitelisted_4 ] = await ethers.getSigners();
 
    Token = await ethers.getContractFactory("TestERC20");
    LockedAccount= await ethers.getContractFactory("LockedAccount");

    // deploy contracts
    token = await Token.deploy();
    locked = await LockedAccount.deploy();

    await locked.deployed();
  });
  
  it("should add the Owner to the whitelist", async function () {
    console.log(await locked.connect(owner).getList());

  });

  




});