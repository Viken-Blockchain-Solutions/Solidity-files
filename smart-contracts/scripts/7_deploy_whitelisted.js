async function main() {
    const [ deployer ]  = await ethers.getSigners();
    
    console.log("Deploying smart-contract 'Whitelisted.sol' with the deployer account:", deployer.address);
   
    const Contract= await ethers.getContractFactory("Whitelisted");
  
    const whitelisted = await Contract.deploy();
  
    await whitelisted.deployed();
  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status  :                                                          
        |       Contract owner  :         ${deployer.address}
        |
        |  ------------------------------------------------------------------------------
        |    Contract deployed:
        |  Whitelisted contract at:       ${whitelisted.address}
        ----------------------------------------------------------------------------------
    `); 
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });