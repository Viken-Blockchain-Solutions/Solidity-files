async function main() {
  const [deployer] = await ethers.getSigners();
  
  const Contract = await ethers.getContractFactory("StakingContract", deployer);
  const instance = await Contract.deploy();

  
  console.log(`
    ----------------------------------------------------------------------------------
    |    Deployment Status :                                                          
    |       Contract owner :                          ${deployer.address},              
    |    Contract deployed :                                                      
    |       StakingContract:                          ${instance.address}             
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