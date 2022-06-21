const { ethers } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");

    
describe.only("New721Collection", function () {
    const name = "test bunnies";
    const ticker = "TEST_BUNNIES";
    const feeNumerator = 1000;
    const contractURI = "https://ifwsu1awnie4.usemoralis.com/info.json";
    const baseURI = "https://ifwsu1awnie4.usemoralis.com/json/";
    const salesPrice = parseEther("1");
    
    let ownerConnected, sellerConnected, contract, Contract;

    beforeEach(async () => {

        [ owner, royalty, seller, buyer, randomUser, marketplace ] = await ethers.getSigners();

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
        it('should set the correct token uri', async () => {
            await ownerConnected.mint("00.json");
            expect(await contract.tokenURI(0)).to.be.equal(baseURI + "00.json");
        });
    });

    describe('Approvals and allowance - Happy path', function () {
        it('should allow an account to ( setApproveForAll }', async () => {
            await ownerConnected.mint("00.json");
            await ownerConnected.mint("01.json");

            expect(await ownerConnected.setApprovalForAll(marketplace.address, true))
                .to.emit(contract, "ApprovalForAll")
                .withArgs(owner.address, marketplace.address, true);
        })
        it('should allow an account to transfer from is approval is given', async () => {
            await ownerConnected.mint("00.json");
            await ownerConnected.mint("01.json");

            await ownerConnected.setApprovalForAll(marketplace.address, true);
            expect(await contract.connect(marketplace).transferFrom(owner.address, randomUser.address, 1))
                .to.emit(contract, "Transfer")
                .withArgs(owner.address, randomUser.address, 1);
        })
    })

});    