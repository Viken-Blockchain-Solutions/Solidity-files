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
        const batch = await Batch.deploy();

        await batch.deployed();

        const batch_owner = batch.connect(owner);
        batch_spender1 = batch.connect(spender1);
        batch_spender2 = batch.connect(spender2);

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
        
        it("Should emit an event after calling the spreadbatch method.", async function () {
            await batch_spender1.approve(spread.address, five_Ether);

            let tx = await spread.connect(spender1).spreadbatch(
                batch.address,
                [receiver1.address, receiver2.address, receiver3.address], 
                [amount_one, amount_three, amount_one]
            );

            expect(tx).to.emit(batch, 'Transfer');
        });

        it("Should emit an event after calling the spreadbatchSimple method.", async function () {
            await batch_spender2.approve(spread.address, five_Ether);

            let tx = await spread.connect(spender2).spreadbatchSimple(
                batch.address,
                [receiver1.address, receiver2.address, receiver3.address], 
                [amount_one, amount_three, amount_one]
            );

            expect(tx).to.emit(batch, 'Transfer');
        }); 
    });

    describe('Spread - Fail path', async function () {
        beforeEach(async function () {
            spread_spender1 = await spread.connect(spender1);
            spread_spender2 = await spread.connect(spender2);
        });
        it('should revert if the address and values is missing when calling the spreadAsset method.', async function () {
            await expect(spread_spender1.spreadAsset([], [], {value: ethers.constants.Zero}))
                .to.be.reverted;
        });
        it('should revert if one of the address or values is missing when calling the spreadAsset method.', async function () {
            await expect(spread_spender1.spreadAsset([receiver1.address], [], {value: amount_five}))
                .to.be.reverted;
        });
        it('should revert if the ether value is to low', async function () {
            await expect(spread_spender1.spreadAsset([receiver1.address], [amount_six], {value: amount_five}))
                .to.be.reverted;
        });
        it('should revert if the approval is missing before the batch tansaction', async function () {
            await expect(spread_spender2.spreadbatchSimple(batch.address, [receiver1.address], [amount_six]))
                .to.be.reverted;
        });
        it('should revert if one of the address or values is missing when calling the spreadAsset method.', async function () {
            await batch_spender2.approve(spread.address, amount_five);
            await expect(spread_spender2.spreadbatch(batch.address, [], [amount_five]))
                .to.be.reverted;
        });
        it('should revert if the user tries to pass zero arrays.', async function () {
            await batch_spender2.approve(spread.address, amount_five);
            await expect(spread_spender2.spreadbatch(batch, [], []))
                .to.be.reverted;
       });
    });
});    