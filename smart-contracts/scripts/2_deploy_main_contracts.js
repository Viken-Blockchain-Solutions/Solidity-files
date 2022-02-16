
async function main() {
    const [deployer] = await ethers.getSigners();
  
    const Token_contract = await ethers.getContractFactory("TestERC20", deployer);
    const Batch_transfers = await ethers.getContractFactory("BatchPayments", deployer);
    const Trust_fund = await ethers.getContractFactory("ERC20TimeLockedTrustfund", deployer);

    const tokenInstance = await Token_contract.deploy();
    const batchInstance = await Batch_transfers.deploy();
    const trustInstance = await Trust_fund.deploy();

    
    console.log(`
      -------------------------------------------------------------------------------------------------------------------------
      |    Deployment Status  :                                                          
      |       Owner account   :                          ${deployer.address},
      |                   
      |    Contracts deployed :                                                      
      |       TestERC20       :                          ${tokenInstance.address},             
      |       BatchPayments   :                          ${batchInstance.address},             
      |       Trustfund       :                          ${trustInstance.address}             
      |                                                                                
      -------------------------------------------------------------------------------------------------------------------------
    `);
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });