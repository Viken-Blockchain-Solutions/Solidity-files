
async function main() {

    const [ owner, payee1, payee2, payee3, payee4, payee5, payee6 ]  = await ethers.getSigners();
    
    console.log("Deploying RoyaltySplitter.sol with the account:", owner.address);
   
    const Contract= await ethers.getContractFactory("RoyaltySplitter");
  
    const royalty = await Contract.deploy(
        [payee1.address, payee2.address, payee3.address, payee4.address, payee5.address, payee6.address],
        [10,10,10,10,10,50]
    );
  
    await royalty.deployed();
  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status  :                                                          
        |       Contract owner  :         ${owner.address}
        |  ------------------------------------------------------------------------------
        |    Contract deployed  :
        |       RoyaltySplitter :         ${royalty.address}
        |
                        Payees  :       ${payee1.address} - 10
                                        ${payee2.address} - 10
                                        ${payee3.address} - 10
                                        ${payee4.address} - 10
                                        ${payee5.address} - 10
                                        ${payee6.address} - 50
        ----------------------------------------------------------------------------------
    `); 
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });