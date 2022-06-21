const { ethers } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");

    
describe("RoyaltySplitter", function () {

    beforeEach(async () => {
        [ owner, payee1, payee2, payee3, payee4, payee5, payee6 ]  = await ethers.getSigners();
           
        const Contract= await ethers.getContractFactory("RoyaltySplitter");
        const royalty = await Contract.deploy(
            [payee1.address, payee2.address, payee3.address, payee4.address, payee5.address, payee6.address],
            [10,10,10,10,10,50]
        );
          
        await royalty.deployed();
    });
    describe('Admin features', function () {
        
        it("should print the related address for these tests.", async function () {
            console.log(`
                Test accounts:
    
                    Owner Account  :       ${owner.address},
                    Payee1 Account :       ${payee1.address},
                    Payee2 Account :       ${payee2.address},
                    Payee3 Account :       ${payee3.address},
                    Payee4 Account :       ${payee4.address},
                    Payee5 Account :       ${payee5.address},
                    Payee6 Account :       ${payee6.address}
            `);
        }); 
    });

});
