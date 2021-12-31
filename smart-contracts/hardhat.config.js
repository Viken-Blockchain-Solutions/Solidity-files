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
  solidity: "0.8.11",
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: true,
  }
};
