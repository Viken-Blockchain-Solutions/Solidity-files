const { ethers } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");

    
describe("New721Collection", function () {
    const name = "test bunnies";
    const ticker = "TEST_BUNNIES";
    const feeNumerator = 1000;
    const contractURI = "https://ifwsu1awnie4.usemoralis.com/info.json";
    const salesPrice = parseEther("1");
    
    let ownerConnected, sellerConnected, contract, Contract;

    beforeEach(async () => {

        [ owner, royalty, seller, buyer, randomUser ] = await ethers.getSigners();

        Contract = await ethers.getContractFactory('New721Collection');
        contract = await Contract.deploy(name, ticker, royalty.address, feeNumerator);

        await contract.deployed();

        ownerConnected = contract.connect(owner);
        sellerConnected = contract.connect(seller);
    });

    describe('Admin - Happy path', function () {
        it('should deploy the contract with the correct owner', async () => {
            expect(await ownerConnected.owner()).to.be.equal(owner.address);
        });
        it('should deploy the contract with the correct name', async () => {
            expect(await ownerConnected.name()).to.be.equal(name);
        });
        it('should deploy the contract with the correct ticker', async () => {
            expect(await ownerConnected.symbol()).to.be.equal(ticker);
        });
        it('should return the contractURI', async () => {
            expect(await ownerConnected.contractURI()).to.be.equal(contractURI);
        });
    });
    describe('Minting - Happy path', function () {
        it('should allow the owner to mint', async () => {
            expect(await ownerConnected.mint("00.json"))
                .to.emit(contract, "Mint")
                    .withArgs(owner.address, 0, "00.json");
        });
        it('should return the correct royalty info', async () => {
            await ownerConnected.mint("00.json");
            const royaltyInfo = await contract.royaltyInfo(0, salesPrice);
            expect(await royaltyInfo[0]).to.be.equal(royalty.address);
            expect(await royaltyInfo[1].toString()).to.be.equal("100000000000000000");
        });
    });

});    