
async function main() {
    const [deployer] = await ethers.getSigners();
  
    const Contract = await ethers.getContractFactory("ERC20TimeLockedTrustfund", deployer);
    const instance = await Contract.deploy();
    
    console.log(`
      ----------------------------------------------------------------------------------
      |    Deployment Status :                                                          
      |       Contract owner :                          ${deployer.address},                   
      |    Contract deployed :                                                      
      |       trustfund      :                          ${instance.address}             
      |                                                                                
      ----------------------------------------------------------------------------------
    `);
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });