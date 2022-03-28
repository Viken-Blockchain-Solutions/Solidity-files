async function main() {
    const [ deployer ]  = await ethers.getSigners();
    
    console.log("Deploying MintableERC1155 with the account:", deployer.address);
   
    const NFTContract = await ethers.getContractFactory("MintableERC1155");
  
    const erc1155 = await NFTContract.deploy();
  
    await erc1155.deployed();
  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status  :                                                          
        |       Contract owner  :         ${deployer.address}
        |
        |  ------------------------------------------------------------------------------
        |   Contracts deployed  :
        |   Collection:
        |     MintableERC1155   :         ${erc1155.address}
        ----------------------------------------------------------------------------------
    `); 
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });