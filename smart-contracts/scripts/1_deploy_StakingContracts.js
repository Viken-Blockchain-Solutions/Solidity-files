
async function main() {
  const [deployer, devAddr, feeAddr] = await ethers.getSigners();

  const erc20PerBlock = 100;
  
  // UnixTimestamp 
  const startBlock = 1641755541; // Sun Jan 09 2022 20:12:21 GMT+0100 (sentraleuropeisk normaltid)


  const testERC20 = await ethers.getContractFactory("testERC20", deployer);

  const Staking = await ethers.getContractFactory("StakingContract", deployer);
  const CENT = await ethers.getContractFactory("MasterChef_CENT", deployer);
  const OLIVE = await ethers.getContractFactory("MasterChef_OLIVE", deployer);

  const erc20 = await testERC20.deploy();
  const erc20Name = await erc20.name();
  const staking = await Staking.deploy(erc20.address);
  const cent = await CENT.deploy(
    erc20.address,
    devAddr.address,
    feeAddr.address,    
    erc20PerBlock,
    startBlock
  );
  
  const olive = await OLIVE.deploy(
    erc20.address,
    devAddr.address,
    erc20PerBlock,
    startBlock
  );  
  
  console.log(`
    ----------------------------------------------------------------------------------
    |    Deployment Status  :                                                          
    |       Contracts owner :                          ${deployer.address},
    |       Address dev     :                          ${devAddr.address},
    |       Address fee     :                          ${feeAddr.address}
    |
    |    Contract deployed  :
    |       TestERC20       :                          ${erc20.address}
    |
    |       StakingContract :                          ${staking.address},            
    |         staked token  :                          ${erc20Name}
    |         
    |       MasteChef_CENT  :                          ${cent.address},
    |         staked token  :                          ${erc20Name},       
    |         erc20PerBlock :                          ${erc20PerBlock.toString()},           
    |         startBlock    :                          ${startBlock.toString()}
    |
    |       MasteChef_OLIVE :                          ${olive.address},
    |         staked token  :                          ${erc20Name},
    |         erc20PerBlock :                          ${erc20PerBlock.toString()},           
    |         startBlock    :                          ${startBlock.toString()}            
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