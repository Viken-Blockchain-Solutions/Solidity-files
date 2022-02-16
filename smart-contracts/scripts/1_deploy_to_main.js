
require("dotenv/config");

async function main() {
  const [ deployer, fee ]  = await ethers.getSigners();

  console.log("Deploying contracts with the account:" );

  const devAddr = `${process.env.DEV}`;
  
  const Vault = await ethers.getContractFactory("TicketVault");
  const Token = await ethers.getContractFactory("CentaurifyToken");
  
  const token = await Token.deploy();
  const vault = await Vault.deploy(token.address, fee.address);


  console.log(`
      ----------------------------------------------------------------------------------
      |    Deployment Status  :                                                          
      |       Contract owner  :                          ${deployer.address},
      |       Fee address     :                          ${fee.address}
      |
      |  ------------------------------------------------------------------------------
      |    Contract deployed  :
      |       Centaurify token:                          ${token.address} 
      |       TicketVault     :                          ${vault.address}
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