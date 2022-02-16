// test/3_batch_payments.test.js
const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');



// Use the different accounts, which are unlocked and funded with Ether
const [ admin, deployer, user ] = accounts;

// Create a contract object from a compilation artifact
const BatchContract = contract.fromArtifact('BatchPayments');
const TokenContract = contract.fromArtifact('TestERC20');

// Start test block
describe('BatchContract', function () {
  // Use the different accounts, which are unlocked and funded with Ether
  const [ admin, deployer, sender, receiver1, receiver2, receiver3 ] = accounts;

  beforeEach(async function () {
     // The bundled BN library is the same one web3 uses under the hood.
    this.value = new BN(2);

    this.batchInstance = await BatchContract.new({ from: owner });
    this.tokenInstance = await TokenContract.new({ from: owner });
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