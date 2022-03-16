async function main() {
    const [ deployer ]  = await ethers.getSigners();
    
    console.log("Deploying contracts with the account:", deployer.address);
   
    const Locked = await ethers.getContractFactory("LockedAccount");
  
    const locked = await Locked.deploy();
  
  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status  :                                                          
        |       Contract owner  :         ${deployer.address}
        |
        |  ------------------------------------------------------------------------------
        |    Contract deployed  :
        |       LockedAccount   :         ${locked.address}
        ----------------------------------------------------------------------------------
    `); 
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });