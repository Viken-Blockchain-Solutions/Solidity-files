async function main() {
  const [ deployer ]  = await ethers.getSigners();
  
  console.log("Deploying contracts with the account:", deployer.address);
 
  const Cent = await ethers.getContractFactory("CentaurifyToken");
  const Vault = await ethers.getContractFactory("TicketVault");

  const cent = await Cent.deploy();
  const vault = await Vault.deploy(cent.address);


  console.log(`
      ----------------------------------------------------------------------------------
      |    Deployment Status  :                                                          
      |       Contract owner  :                          ${deployer.address}
      |       Fee address     :                          0x0B818e6e9Bf4c87f437FF84F6aabecB728398b51
      |
      |  ------------------------------------------------------------------------------
      |    Contract deployed  :
      |       TokenAddress    :                          ${cent.address}
      |       ticketVault     :                          ${vault.address}
      ----------------------------------------------------------------------------------
  `); 
}
  
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });