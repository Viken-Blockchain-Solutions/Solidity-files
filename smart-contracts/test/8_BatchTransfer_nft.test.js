const { ethers } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");

    
describe("Spread_dApp", function () {
    
    let owner, spender1, spender2, receiver1, receiver2, receiver3;
    let batch_spender1, batch_spender2, batch;
    
    let ten_Ether = parseEther("10");
    let five_Ether = parseEther("5");

    let amount_one = parseEther('0.1');
    let amount_two = parseEther('0.2');
    let amount_three = parseEther('0.3');
    let amount_four = parseEther('0.4');
    let amount_five = parseEther('0.5');
    let amount_six = parseEther('0.6');
    let amount_minus_six = parseEther('-0.6');

    before(async function () {
        [ owner, spender1, spender2, receiver1, receiver2, receiver3 ] = await ethers.getSigners();

        const Batch = await ethers.getContractFactory("BatchTransferNft");
        Token = await ethers.getContractFactory("TestERC20");
        const Nft = await ethers.getContractFactory("MockNft");
        const batch = await Batch.deploy();
        const nft = await Nft.deploy();
        token = await Token.deploy();

        await batch.deployed();
        await nft.deployed();
        await token.deployed();
        

        await token.connect(owner).mint(spender1.address, 1000000000000000000000000n);
        await token.connect(owner).mint(spender2.address, 1000000000000000000000000n);
        await token.connect(spender1).approve(batch.address, 1000000000000000000000000n);
        await token.connect(spender2).approve(batch.address, 1000000000000000000000000n);
    
        before1 = await token.connect(spender1).balanceOf(spender1.address);
        before2 = await token.connect(spender2).balanceOf(spender2.address);

    });

    beforeEach(async function () {
        const Contract = await ethers.getContractFactory("Spread");
        spread = await Contract.deploy();
        await spread.deployed();
    });

    describe('Admin features', function () {
        
        it("should print the related address for these tests.", async function () {
            console.log(`
                Test accounts:
                    Spread Contract   :       ${spread.address},
                    Owner Account     :       ${owner.address},
                    Spender1 Account  :       ${spender1.address},
                    Spender2 Account  :       ${spender2.address},
                    receiver1 Account :       ${receiver1.address},
                    receiver2 Account :       ${receiver2.address},
                    receiver3 Account :       ${receiver3.address}
            `);
        }); 
    });

    describe('Spread - Happy path', function () {
        it("should execute a batch transfer of Ether to three accounts and check balances after.", async function () {
          
            let tx = await spread.connect(spender1).spreadAsset(
                [ receiver1.address, receiver2.address, receiver3.address ],
                [ amount_one, amount_two, amount_three],
                { value: amount_six, }
            );

            await expect(() => tx).to.changeEtherBalances(
                [spender1, receiver1, receiver2, receiver3],
                [amount_minus_six, amount_one, amount_two, amount_three]
            );
        
        });
        
        it("Should emit an event after calling the spreadERC20 method.", async function () {
        });
       
    });
});    