// test/3_batch_payments.test.js
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');


// Start test block
describe('BatchContract', function ([ deployer, sender, receiver1, receiver2, receiver3 ]) {
  // Create a contract object from a compilation artifact
  beforeEach(async function () {
    // The bundled BN library is the same one web3 uses under the hood.
    this.value = new BN(2);
    
    const TokenContract = await ethers.getContractFactory("TestERC20");
    const BatchContract = await ethers.getContractFactory('BatchPayments');
    
    this.tokenInstance = await TokenContract.deployed();
    this.batchInstance = await BatchContract.deployed();
  });

  it('updates balances on successful ERC20 transfers', async function () {
    const receipt = await this.batchInstance.batchERC20Payments(
      [ receiver1, receiver2, receiver3 ], 
      [ this.value, this.value, this.value ], 
      { from: sender }
    );

    // BN assertions are automatically available via chai-bn (if using Chai)
    expect(await this.tokenInstance.balanceOf(receiver1))
      .to.be.bignumber.equal(this.value);
  });
  it('batchEtherPayments emits an event for each transaction', async function () {
    const receipt = await this.batchInstance.batchEtherPayments(
      [ receiver1, receiver2, receiver3 ], 
      [ this.value, this.value, this.value ], 
      { from: sender }
    );

    // Event assertions can verify that the arguments are the expected ones.
    expectEvent(receipt, 'Transfer', { 
      from: owner,
      to: addr1,
      value: this.value,
    });
  });
});