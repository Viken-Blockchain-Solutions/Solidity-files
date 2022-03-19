
async function main() { 
  const [deployer, admin] = await ethers.getSigners();

  const TestToken_contract = await ethers.getContractFactory("TestERC20", deployer);
  const Batch = await ethers.getContractFactory("BatchPayments", deployer);
  const Trust_fund = await ethers.getContractFactory("ERC20TimeLockedTrustfund", deployer);
  const Erc20Proxy = await ethers.getContractFactory("ERC20Proxy");
  const Ticket = await ethers.getContractFactory("TicketVault");
  const Locked = await ethers.getContractFactory("LockedAccount");
  const Erc721 = await ethers.getContractFactory("MintableERC721");
  const Erc1155 = await ethers.getContractFactory("MintableERC1155");

  // Deploy smart-contracts
  const testerc20 = await TestToken_contract.deploy();
  const trust = await Trust_fund.deploy();
  const locked = await Locked.deploy();

  const ticket = await Ticket.deploy(testerc20.address);
  const erc20Proxy = await Erc20Proxy.deploy();
  const batch = await Batch.deploy(erc20Proxy.address);

  const erc721 = await Erc721.deploy("CryptoKozo", "KOZO");
  const erc1155 = await Erc1155.deploy("https://japan-nft.com/erc1155/tokenId/1");

  console.log(`
    -------------------------------------------------------------------------------------------------------------------------
    |    Deployment Status  :                                                          
    |       Owner account   :           ${deployer.address},
    |       Admin account   :           ${admin.address}
    |                   
    |    Contracts deployed :                                                                  
    |       TestERC20       :           ${testerc20.address},             
    |       BatchPayments   :           ${batch.address},         
    |       TicketVault     :           ${ticket.address},         
    |       Trustfund       :           ${trust.address},
    |       LockedAccount   :           ${locked.address},
    |       mintableERC721  :           ${erc721.address},           
    |       mintableERC1155 :           ${erc1155.address},           
    |
    |    Client Contracts
    |       ERC20Proxy      :           ${erc20Proxy.address}
    -------------------------------------------------------------------------------------------------------------------------
  `);
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });