require("dotenv/config");

async function main() {
    const deployer  = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer);

    const dev = `${process.env.DEV}`;
    
    const Staking = await ethers.getContractFactory("SingleStaking", deployer);

    const staking = await Staking.deploy(dev);

  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status  :                                                          
        |       Contract owner  :                          ${deployer.address},
        |       Address dev     :                          ${dev},
        |
        |    Contract deployed  :
        |       SingleStaking   :                          ${staking.address}
        |         
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