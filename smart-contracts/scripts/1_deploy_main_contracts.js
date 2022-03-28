
async function main() { 
  const [deployer, admin] = await ethers.getSigners();

  // get smart-contracts.
  const Whitelisted = await ethers.getContractFactory("Whitelisted");
  const TestToken_contract = await ethers.getContractFactory("TestERC20", deployer);
  const Trust_fund = await ethers.getContractFactory("ERC20TimeLockedTrustfund", deployer);
  const Viking = await ethers.getContractFactory("VikingVault");
  const Locked = await ethers.getContractFactory("LockedAccount");
  const Erc20Proxy = await ethers.getContractFactory("ERC20Proxy");
  const Batch = await ethers.getContractFactory("BatchPayments", deployer);
  const Spread = await ethers.getContractFactory("Spread");
  const Marketplace = await ethers.getContractFactory("MarketPlace");
  const MintableERC1155 = await ethers.getContractFactory("MintableERC1155");


  // Deploy smart-contracts.
  const whitelisted = await Whitelisted.deploy();
  const testerc20 = await TestToken_contract.deploy();
  const trust = await Trust_fund.deploy();
  const viking = await Viking.deploy(testerc20.address);
  const locked = await Locked.deploy();

  const erc20Proxy = await Erc20Proxy.deploy();
  const batch = await Batch.deploy(erc20Proxy.address);
  const spread = await Spread.deploy();
  
  const marketplace = await Marketplace.deploy();
  const erc1155 = await MintableERC1155.deploy();

  console.log(`
    ----------------------------------------------------------------------------------------------
    |    Deployment Status    : ----------       ADMIN ACCOUNTS     ---------- 
        
    |       Owner account     :           ${deployer.address},
    |       Admin account     :           ${admin.address}
    |                   
    |    Contracts deployed   : ---------- DEPLOYED SMART-CONTRACTS ----------

          Admin
    |       Whitelisted       :           ${whitelisted.address}
    
          ERC20
    |       TestERC20         :           ${testerc20.address}
    
          Payments
    |       BatchPayments     :           ${batch.address},
    |       Spread Transfers  :           ${spread.address}
          
          Staking   
    |       VikingVault       :           ${viking.address}
          
          Timelocked
    |       Trustfund         :           ${trust.address},
    |       LockedAccount     :           ${locked.address}
          
          NFT
    |       NFT MarketPlace   :           ${marketplace.address},
    |       MintableERC1155   :           ${erc1155.address}
    |     
          Client Contracts
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