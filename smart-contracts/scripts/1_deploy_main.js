require("dotenv/config");

async function main() {
    
  const [ deployer, fee ]  = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const dev = `${process.env.DEV}`;
  
  const Vault = await ethers.getContractFactory("TicketVault");
  const Token = await ethers.getContractFactory("CentaurifyToken");
  
  const vault = await Vault.deploy(fee.address);
  const token = await Token.deploy();


  console.log(`
      ----------------------------------------------------------------------------------
      |    Deployment Status  :                                                          
      |       Contract owner  :                          ${deployer.address},
      |       Fee address     :                          ${fee.address}
      |
      |  ------------------------------------------------------------------------------
      |    Contract deployed  :
      |       TicketVault     :                           ${vault.address}
      |       Centaurify token:                          ${token.address} 
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