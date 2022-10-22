const { ethers } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");

    
describe("BatchTransferNFT_dApp", function () {
    let batch, nft;
    let owner, sender1, sender2, receiver1, receiver2, receiver3, receiver4, receiver5;
    let balance, balance1, balance2;


    before(async function () {
        [ owner, sender1, sender2, receiver1, receiver2, receiver3, receiver4, receiver5 ] = await ethers.getSigners();

        const Batch = await ethers.getContractFactory("BatchTransferNft");
        const Nft = await ethers.getContractFactory("MockNFT");
        batch = await Batch.deploy();
        nft = await Nft.deploy();

        await batch.deployed();
        await nft.deployed();


        for (let i = 0; i < 10; i++) {
            await nft.connect(owner).safeMint(owner.address);
           /*  await nft.connect(owner).safeMint(sender1.address);
            await nft.connect(owner).safeMint(sender2.address); */
        }

        balance = await nft.balanceOf(owner.address);
        balance1 = await nft.balanceOf(sender1.address);
        balance2 = await nft.balanceOf(sender2.address);
    });

    describe('Admin features', function () {
        
        it("should print the related address for these tests.", async function () {
            console.log(`
                Test accounts:
                    Batch Contract   :       ${batch.address},
                    Owner Account     :       ${owner.address},
                    Spender1 Account  :       ${sender1.address},
                    Spender2 Account  :       ${sender2.address},
                    receiver1 Account :       ${receiver1.address},
                    receiver2 Account :       ${receiver2.address},
                    receiver3 Account :       ${receiver3.address},
                    receiver4 Account :       ${receiver4.address},
                    receiver5 Account :       ${receiver5.address},
                    owner nft:                ${balance},
                    sender1 nft:              ${balance1},
                    sender2 nft:              ${balance2}
            `);
        }); 
    });

/*     describe('Spread - Happy path', function () {
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
    }); */

    describe("BatchNFTPayments- Happy path", function () {

        it("Should allow a user to batch transfer ten NFT's to five different accounts", async function () {
            await nft.connect(owner).setApprovalForAll(batch.address, true);
            await batch.connect(owner).spreadERC721(
                nft.address, 
                [receiver1.address, receiver2.address, receiver3.address, receiver4.address, receiver5.address], 
                [[0,1],[2,3],[4,5],[6,7],[8,9]],
                { value: parseEther("0.005"), }
            );
            let balance1 = await nft.balanceOf(receiver1.address);
            let balance2 = await nft.balanceOf(receiver2.address);
            let balance3 = await nft.balanceOf(receiver3.address);
            let balance4 = await nft.balanceOf(receiver4.address);
            let balance5 = await nft.balanceOf(receiver5.address);
            expect(await balance1.toString()).to.eql("2");
            expect(await balance2.toString()).to.eql("2");
            expect(await balance3.toString()).to.eql("2");
            expect(await balance4.toString()).to.eql("2");
            expect(await balance5.toString()).to.eql("2");
        });
    })
});    