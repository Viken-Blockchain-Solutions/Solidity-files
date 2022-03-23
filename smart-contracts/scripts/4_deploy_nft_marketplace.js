async function main() {
    const [ deployer ]  = await ethers.getSigners();
    
    console.log("Deploying Marketplace with the account:", deployer.address);
   
    const MarketplaceContract = await ethers.getContractFactory("MarketPlace");
  
    const marketplace = await MarketplaceContract.deploy();
  
    await marketplace.deployed();
  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status  :                                                          
        |       Contract owner  :         ${deployer.address}
        |
        |  ------------------------------------------------------------------------------
        |   Contracts deployed  :
        |       MarketPlace     :         ${marketplace.address}
        ----------------------------------------------------------------------------------
    `); 
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });