
async function main() {
    const [deployer] = await ethers.getSigners();
  
    const Token_contract = await ethers.getContractFactory("TestERC20", deployer);
    const Batch = await ethers.getContractFactory("BatchPayments", deployer);
    const Trust_fund = await ethers.getContractFactory("ERC20TimeLockedTrustfund", deployer);
    const EthProxy = await ethers.getContractFactory("EthereumProxy");
    const Erc20Proxy = await ethers.getContractFactory("ERC20Proxy");

    const token = await Token_contract.deploy();
    const trust = await Trust_fund.deploy();
    const erc20Proxy = await Erc20Proxy.deploy();
    const ethProxy = await EthProxy.deploy();
    const batch = await Batch.deploy(erc20Proxy.address, ethProxy.address);

    
    console.log(`
      -------------------------------------------------------------------------------------------------------------------------
      |    Deployment Status  :                                                          
      |       Owner account   :                          ${deployer.address},
      |                   
      |    Contracts deployed :                                                      
      |       Ethereum Proxy  :                          ${ethProxy.address},             
      |       ERC20Proxy      :                          ${erc20Proxy.address},             
      |       TestERC20       :                          ${token.address},             
      |       BatchPayments   :                          ${batch.address},             
      |       Trustfund       :                          ${trust.address}             
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