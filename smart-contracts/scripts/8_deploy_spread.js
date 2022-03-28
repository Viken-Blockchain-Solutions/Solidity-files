async function main() {
    const [ deployer ]  = await ethers.getSigners();
    
    console.log("Deploying Spread contract with the account:", deployer.address);
   
    const Contract= await ethers.getContractFactory("Spread");
  
    const spread = await Contract.deploy();
  
    await spread.deployed();
  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status  :                                                          
        |       Contract owner  :         ${deployer.address}
        |
        |  ------------------------------------------------------------------------------
        |    Contract deployed  :
        |       Spread contract :         ${spread.address}
        ----------------------------------------------------------------------------------
    `); 
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });