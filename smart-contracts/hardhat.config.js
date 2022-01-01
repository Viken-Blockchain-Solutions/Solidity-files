require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-solhint");
require("@nomiclabs/hardhat-ganache");
require("hardhat-docgen");
require("hardhat-spdx-license-identifier");


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
      url: "https://eth-rinkeby.alchemyapi.io/v2/YOUR_API_KEY_HERE",
    },
    ropsten: {
      url: "https://eth-ropsten.alchemyapi.io/v2/YOUR_API_KEY_HERE",
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  }
};
