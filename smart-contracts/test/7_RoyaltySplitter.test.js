const { ethers } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");

    
describe.only("RoyaltySplitter", function () {
    let asOwner, royalty; 
    let one_Ether = parseEther("1");

    beforeEach(async () => {
        [ owner, payee1, payee2, payee3, payee4, payee5, payee6 ]  = await ethers.getSigners();
           
        const Contract= await ethers.getContractFactory("RoyaltySplitter");
        royalty = await Contract.deploy(
            [payee1.address, payee2.address, payee3.address, payee4.address, payee5.address, payee6.address],
            [10,10,10,10,10,50]
        );
          
        await royalty.deployed();
        
        asOwner = royalty.connect(owner);
    });

    describe('Splitter data', function () {
        it("should have the correct addresses.", async () => {
            expect(await asOwner.payee(0)).to.be.equal(payee1.address);
            expect(await asOwner.payee(1)).to.be.equal(payee2.address);
            expect(await asOwner.payee(2)).to.be.equal(payee3.address);
            expect(await asOwner.payee(3)).to.be.equal(payee4.address);
            expect(await asOwner.payee(4)).to.be.equal(payee5.address);
            expect(await asOwner.payee(5)).to.be.equal(payee6.address);
        })
        it("should have the correct Shares to Account connection.", async () => {
            expect(await asOwner.shares(payee1.address)).to.be.equal(10);
            expect(await asOwner.shares(payee2.address)).to.be.equal(10);
            expect(await asOwner.shares(payee3.address)).to.be.equal(10);
            expect(await asOwner.shares(payee4.address)).to.be.equal(10);
            expect(await asOwner.shares(payee5.address)).to.be.equal(10);
            expect(await asOwner.shares(payee6.address)).to.be.equal(50);
        })
    });
    describe('Receive and Payout of funds', function () {
        it('should have emitted an event if contract received 1 Ether', async () => {
            let tx = {
                to: royalty.address,
                value: ethers.utils.parseEther("1")
            }

            expect(await owner.sendTransaction(tx))
                .to.emit(royalty, "PaymentReceived")
                .withArgs(owner.address, parseEther("1"));

        })
        it('should have split the incoming 1 eth payment between all accounts', async () => {
            let tx = {
                to: royalty.address,
                value: ethers.utils.parseEther("1")
            }
            await owner.sendTransaction(tx);

   
        })
    })
});
