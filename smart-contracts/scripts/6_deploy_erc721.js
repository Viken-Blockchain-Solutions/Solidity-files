async function main() {
    const [ deployer ]  = await ethers.getSigners();
    
    console.log("Deploying CentaurifyBase721.sol with the account:", deployer.address);
   
    const NFTContract = await ethers.getContractFactory("CentaurifyBase721");
  
    const erc721 = await NFTContract.deploy("Centaurify-Team", "CENT_TEAM", 1000);
  
    await erc721.deployed();
  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status  :                                                          
        |       Contract owner  :         ${deployer.address}
        |
        |  ------------------------------------------------------------------------------
        |   Contracts deployed  :
        |    Collection:
        |      CentaurifyBase721:         ${erc721.address}
        ----------------------------------------------------------------------------------
    `); 
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });