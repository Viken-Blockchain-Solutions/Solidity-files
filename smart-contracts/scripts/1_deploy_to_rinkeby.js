require("dotenv/config");

async function main() {
    const [deployer]  = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const dev = `${process.env.DEV}`;
    
    const Staking = await ethers.getContractFactory("SingleStaking");
    const Token = await ethers.getContractFactory("testERC20");
    
    const staking = await Staking.deploy(dev, 1000000000000000000n);
    const token = await Token.deploy(1000000000000000000000000000n);

  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status  :                                                          
        |       Contract owner  :                          ${deployer.address},
        |       Address dev     :                          ${dev},
        |
        |    Contract deployed  :
        |       SingleStaking   :                          ${staking.address}
        |       testERC20       :                          ${token.address} 
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