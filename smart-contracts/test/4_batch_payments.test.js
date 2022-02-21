// Apply configuration
require('@openzeppelin/test-helpers/configure')({
  provider: 'http://localhost:8545',
});

const { expect } = require("chai");
const {
  BN,           // Big Number support
} = require('@openzeppelin/test-helpers');

describe("BatchPayments", function () {

  let owner, spender1, spender2, receiver1, receiver2, receiver3;
  let Token, Batch, EthProxy, Erc20Proxy, token, erc20Proxy, ethProxy, batch;
  let before1, before2, after1, after2;
  let referenceExample1 = '0xaaaa';
  let referenceExample3 = '0xbbbb';
  let referenceExample2 = '0xcccc';

  before(async function () {
    // Get the ContractFactory and Signers here.
    [owner, spender1, spender2, receiver1, receiver2, receiver3] = await ethers.getSigners();
 
    Token = await ethers.getContractFactory("TestERC20");
    Batch = await ethers.getContractFactory("BatchPayments");
    Erc20Proxy = await ethers.getContractFactory("ERC20Proxy");

    // deploy contracts
    token = await Token.deploy();
    erc20Proxy = await Erc20Proxy.deploy();
    batch = await Batch.deploy(erc20Proxy.address);
    
    await token.connect(owner).mint(spender1.address, 1000000000000000000000000n);
    await token.connect(owner).mint(spender2.address, 1000000000000000000000000n);
    await token.connect(spender1).approve(batch.address, 1000000000000000000000000n);
    await token.connect(spender2).approve(batch.address, 1000000000000000000000000n);

    before1 = await token.connect(spender1).balanceOf(spender1.address);
    before2 = await token.connect(spender2).balanceOf(spender2.address);
    

  });

  it("Should execute a batch of Ether payments to three accounts", async function () {
    const receipt = await batch.connect(spender1).batchEtherPayment(
      [receiver1.address, receiver2.address, receiver3.address],
      [2000000000000000000n, 2000000000000000000n, 2000000000000000000n],
      { value: 6000000000000000000n, }
    );
    
    expect(await receipt).to.emit(batch, 'EthTransfer');
  });

  it("Should execute a batch of ERC20 payments to three accounts", async function () {
    await expect(
      batch.connect(spender1).batchERC20Payment(
        token.address,
        [receiver1.address, receiver2.address, receiver3.address], 
        [2000000000000000000n, 2000000000000000000n, 2000000000000000000n]
      ))
      .to.emit(token, 'Transfer')
      .withArgs(spender1.address, receiver1.address, 2000000000000000000n);
  });

  it("Should execute multiple ERC20 payments w/ paymentReference, through the ERC20Proxy", async function () {
    await expect(
      batch.connect(spender2).batchERC20PaymentWithReference(
        token.address,
        [receiver1.address, receiver2.address, receiver3.address],
        [20, 20, 20],
        [referenceExample1, referenceExample2, referenceExample3]
        ))
        .to.emit(token, 'Transfer');
          
    it("MetaData:", async function () {
      after1 = await token.connect(spender1).balanceOf(spender1.address);
      after2 = await token.connect(spender2).balanceOf(spender2.address);
      
      console.log(`
        Token address      :     ${token.address}
        ERC20Proxy address :     ${erc20Proxy.address}
        EthProxy address   :     ${ethProxy.address}
        Batch address      :     ${batch.address}

        Spender1 token before balance  :     ${balance1},
        Spender2 token before balance  :     ${balance2}
        
        Spender1 token after balance   :     ${after1},
        Spender2 token after balance   :     ${after2}
      `)
    });
  });
});
''