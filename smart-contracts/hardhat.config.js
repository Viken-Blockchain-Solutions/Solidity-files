require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-solhint");
require("@nomiclabs/hardhat-ganache");
require("hardhat-docgen");
require("hardhat-spdx-license-identifier");
require("dotenv/config");

const etherScanApiKey = process.env.ETHERSCAN_API_KEY;
const rinkebyApiKey = process.env.ALCHEMY_APIKEY_RINKEBY;
const ropstenApiKey = process.env.ALCHEMY_APIKEY_ROPSTEN;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: false,
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
    rinkeby: {
      url: rinkebyApiKey,
      chainId: 4,
      account: [process.env.ACCOUNT_PRIVATE_KEY]
    },
    ropsten: {
      url: ropstenApiKey,
      chainId: 3,
      account: [process.env.ACCOUNT_PRIVATE_KEY]
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
  }
};

