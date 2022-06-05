const { ethers } = require("hardhat");
const { expect } = require("chai");
const { parseEther } = require("ethers/lib/utils");
const { getContractFactory } = require("@nomiclabs/hardhat-ethers/types");

    
describe.only("New721Collection", function () {
    const name = "test bunnies";
    const ticker = "TEST_BUNNIES";
    const feeNumerator = 1000;
    
    let ownerConnected, sellerConnected, Contract, contract;

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
    });
    describe('Minting - Happy path', function () {
        it('should allow the owner to mint', async () => {
            expect(await ownerConnected.mint("00.json"))
                .to.emit(contract, "Mint")
                    .withArgs(owner.address, 0, "00.json");
        });
    });

});    