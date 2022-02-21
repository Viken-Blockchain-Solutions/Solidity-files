async function main() {
  const dev = `${process.env.DEV}`;
  const [ deployer ]  = await ethers.getSigners();
  
  console.log("Deploying contracts with the account:", dev);
  
  const Vault = await ethers.getContractFactory("TicketVault");
  console.log("about to deploy");

  const vault = await Vault.deploy("0x3d8414bb782Bb679Ca61BB48B77ad5Ba0F10C390", "0x0B818e6e9Bf4c87f437FF84F6aabecB728398b51");


  console.log(`
      ----------------------------------------------------------------------------------
      |    Deployment Status  :                                                          
      |       Contract owner  :                          ${dev},
      |       Fee address     :                          0x0B818e6e9Bf4c87f437FF84F6aabecB728398b51
      |
      |  ------------------------------------------------------------------------------
      |    Contract deployed  :
      |       ticketVault     :                          ${vault,address},
      |       TokenAddress    :                          0x3d8414bb782Bb679Ca61BB48B77ad5Ba0F10C390
      ----------------------------------------------------------------------------------
  `); 
}
  
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });