async function main() {
    const [ deployer, royaltyReceiver ]  = await ethers.getSigners();
    const name = 'Test_BECH_Collection';
    const ticker = 'TEST_BECH_COLLECTION';

    console.log("Deploying New721Collection contract with the deployer:", deployer.address);
   
    const Contract= await ethers.getContractFactory("New721Collection");
  
    const contract = await Contract.deploy(name, ticker, royaltyReceiver.address, 1000);
  
    await contract.deployed();
  
    console.log(`
        ----------------------------------------------------------------------------------
        |    Deployment Status :                                                          
        |       Contract owner   :  ${deployer.address}
        |
        |  ------------------------------------------------------------------------------
        |    Contract deployed :
        |       New721Collection :  ${contract.address},
        |       Name   :            ${name},
        |       Ticker :            ${ticker},
        |       royaltyReceiver :   ${royaltyReceiver.address},
        |       royaltyFee :        1000
        ----------------------------------------------------------------------------------
    `); 
  }
    
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });