

const { expect } = require("chai");
const { BN } = require('@openzeppelin/test-helpers');




describe("MintableERC1155 unit test", () => {
    
    let contractOwner, users;
    
    before(async function () {
      // Get the ContractFactory and Signers here.
      [ contractOwner, users ] = await ethers.getSigners();
    
      Erc1155Contract = await ethers.getContractFactory("MintableERC1155");
    
      // deploy contracts
      erc1155 = await Erc1155Contract.deploy("https://Coolest/fucking/NFTid");
    
      await erc1155.deployed();
    });
  
    it("MintableERC1155 TEST: mint collection, totalsupply...", async () => {
        const DEF_URL = "http://IPFSURLHERE"
        const { myContract, contractOwner, users } = await setupTest();

        const test1 = await myContract.totalSupply();
        const test2 = await myContract.balanceOf(contractOwner, 0);
        const test4 = await myContract.uri(0);
        const test5 = await myContract.getNftDetails(0);

        console.log(`
        totalSup:${test1} \n
        balanceOf:${test2} \n
        tokenUri: ${test4} \n
        getNftDetails: ${test5} \n
        `)

        // totalSupply contract should be 1 nft at the start (minted on fixture)
        expect(await myContract.totalSupply()).to.be.equal(1);
        // balanceOf contract should be same as totalSupply at these point
        expect(await myContract.balanceOf(contractOwner, 0)).to.be.equal(10);
        
        // minting new nft, expect Transfer event
        await expect(myContract.newCollection(10, DEF_URL))
        .to.emit(myContract, 'TransferSingle')
        .withArgs(contractOwner, '0x0000000000000000000000000000000000000000', contractOwner, 1, 10);

        // REVERT, onlyOwner can mint new nfts
        await expect(myContract.connect(users[1]).newCollection(10, DEF_URL)).to.be.revertedWith(
          "ERC1155PresetMinterPauser: must have minter role to mint"
        );

        // totalSupply contract should be 2 nfts
        expect(await myContract.totalSupply()).to.be.equal(2);
        // balanceOF contractOwner should be 2 nfts
        expect(await myContract.balanceOf(contractOwner, 1)).to.be.equal(10);

        // setIpfsUri tokenId=1, expect IpfsUriChanged event
        await expect(myContract.setIpfsUri(1, "NEWIPFSURI"))
        .to.emit(myContract, 'IpfsUriChanged')
        .withArgs(contractOwner, 1, DEF_URL, "NEWIPFSURI");
        
        // REVERT setIpfsUri, only URI MANAGER can change uri
        await expect(myContract.connect(users[1]).setIpfsUri(1, "FAILURL")).to.be.revertedWith(
          "ERC1155: must have URI MANAGER role to change uri"
        );

        // REVERT setIpfsUri, tokenId out of totalSupply
        await expect(myContract.setIpfsUri(10, "FAILURL")).to.be.revertedWith(
          "ERC1155: operator query for nonexistent token"
        );

    })
  });