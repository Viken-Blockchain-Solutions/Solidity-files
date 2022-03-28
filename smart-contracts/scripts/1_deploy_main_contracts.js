
async function main() { 
  const [deployer, admin] = await ethers.getSigners();

  // get smart-contracts.
  const Whitelisted = await ethers.getContractFactory("Whitelisted");
  const TestToken_contract = await ethers.getContractFactory("TestERC20", deployer);
  const Trust_fund = await ethers.getContractFactory("ERC20TimeLockedTrustfund", deployer);
  const Ticket = await ethers.getContractFactory("TicketVault");
  const Locked = await ethers.getContractFactory("LockedAccount");
  const Erc20Proxy = await ethers.getContractFactory("ERC20Proxy");
  const Batch = await ethers.getContractFactory("BatchPayments", deployer);
  const Spread = await ethers.getContractFactory("Spread");
  const Marketplace = await ethers.getContractFactory("MarketPlace");


  // Deploy smart-contracts.
  const whitelisted = await Whitelisted.deploy();
  const testerc20 = await TestToken_contract.deploy();
  const trust = await Trust_fund.deploy();
  const ticket = await Ticket.deploy(testerc20.address);
  const locked = await Locked.deploy();

  const erc20Proxy = await Erc20Proxy.deploy();
  const batch = await Batch.deploy(erc20Proxy.address);
  const spread = await Spread.deploy();
  
  const marketplace = await Marketplace.deploy();

  console.log(`
    ---------------------------------------------------------------------------------------------------------
    |    Deployment Status    :                                                          
    |       Owner account     :           ${deployer.address},
    |       Admin account     :           ${admin.address}
    |                   
    |    Contracts deployed   :                                                                  
    |       Whitelisted       :           ${whitelisted.address},             
    |       TestERC20         :           ${testerc20.address},             
    |       BatchPayments     :           ${batch.address},         
    |       TicketVault       :           ${ticket.address},         
    |       Trustfund         :           ${trust.address},
    |       LockedAccount     :           ${locked.address},
    |       NFT MarketPlace   :           ${marketplace.address},
    |       Spread Transfers  :           ${spread.address}
    |
    |    Client Contracts
    |       ERC20Proxy        :           ${erc20Proxy.address}
    ---------------------------------------------------------------------------------------------------------
  `);
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });