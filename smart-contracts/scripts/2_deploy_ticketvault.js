async function main() {
  const [ deployer ]  = await ethers.getSigners();
  
  console.log("Deploying contracts with the account:", deployer.address);
 
  const Vault = await ethers.getContractFactory("TicketVault");

  const token = "CONTRACT_ADDRESS";
  const vault = await Vault.deploy(token);

  const feeAddress = await vault.connect(deployer).feeAddress();
  const VaultInfo = await vault.vault();

  console.log(`
      ----------------------------------------------------------------------------------
      |    Deployment Status  :                                                          
      |       Contract owner  :         ${deployer.address}
      |       Fee address     :         ${feeAddress}
      |
      |  ------------------------------------------------------------------------------
      |    Contract deployed  :
      |       TokenAddress    :         ${token}
      |       TicketVault     :         ${vault.address}
      |       StakingPeriod   :         ${VaultInfo.stakingPeriod} Sec.
      ----------------------------------------------------------------------------------
  `); 
}
  
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });