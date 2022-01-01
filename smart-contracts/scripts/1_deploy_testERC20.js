async function main() {
  const [deployer] = await ethers.getSigners();

  const Contract = await ethers.getContractFactory("testERC20", deployer);
  const instance = await Contract.deploy();
  
  console.log(`
    ----------------------------------------------------------------------------------
    |    Deployment Status :                                                          
    |       Contract owner :                          ${deployer.address},                   
    |    Contract deployed :                                                      
    |       testERC20      :                          ${instance.address}             
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