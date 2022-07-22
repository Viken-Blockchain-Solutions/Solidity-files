require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-solhint");
require("@nomiclabs/hardhat-ganache");
require("hardhat-docgen");
require("solidity-coverage");
require("hardhat-spdx-license-identifier");
require("dotenv").config();


const etherScanApiKey = process.env.ETHERSCAN_API_KEY;
const polyScanApiKey = process.env.POLYSCAN_API_KEY;

// alchemy testnet nodes
const ropstenApiKey = process.env.ALCHEMY_APIKEY_ROPSTEN;
const rinkebyApiKey = process.env.ALCHEMY_APIKEY_RINKEBY;
const mumbaiApiKey = process.env.ALCHEMY_APIKEY_MUMBAI;

// alchemy testnet nodes
const polygonApiKey = process.env.ALCHEMY_APIKEY_POLYGON;
const mainApiKey = process.env.ALCHEMY_APIKEY_MAIN;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        } 
      },
      {
        version: "0.8.14",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        } 
      },
    ],
  },
  docgen: {
    path: './docs', 
    clear: true,
    runOnCompile: true,
  },
  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: true,
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    ganache: {
      url: "http://127.0.0.1:8545",
      gasLimit: 6000000000,
      defaultBalanceEther: 10,
    },
    mainnet: {
      url: mainApiKey,
      chainId: 1,
      accounts: [`${process.env.VIKEN_DEPLOYER_PRIVATE_KEY}`]
    },
    rinkeby: {
      url: rinkebyApiKey,
      chainId: 4,
      accounts: [`${process.env.ACCOUNT_PRIVATE_KEY}`]
    },
    ropsten: {
      url: ropstenApiKey,
      chainId: 3,
      accounts: [`${process.env.ACCOUNT_PRIVATE_KEY}`]
    }, 
    mumbai: {
      url: mumbaiApiKey,
      chainId:80001,
      accounts: [`${process.env.ACCOUNT_PRIVATE_KEY}`]
    },
    polygon: {
      chainId:137,
      url: polygonApiKey,
      accounts: [`${process.env.VIKEN_DEPLOYER_PRIVATE_KEY}`]
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  },
  etherscan: {
    apiKey: etherScanApiKey,
  },
  polyscan: {
    apiKey: polyScanApiKey,
  },
};

// task action function receives the Hardhat Runtime Environment as second argument
task("accounts", "Prints accounts", async (_, { web3 }) => {
  console.log(await web3.eth.getAccounts());
});
