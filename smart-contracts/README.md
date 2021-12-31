
# Plugins - Install guide

- @nomiclabs/hardhat-waffle
- @nomiclabs/hardhat-etherscan
- @nomiclabs/hardhat-solhint
- @nomiclabs/hardhat-ganache
- hardhat-docgen
- hardhat-spdx-license-identifier

#

## Install dependencies

### With Yarn

```bash
yarn add -D @nomiclabs/hardhat-ethers ethers @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-etherscan @nomiclabs/hardhat-solhint @nomiclabs/hardhat-ganache hardhat-docgen hardhat-spdx-license-identifier
```

### With npm

```bash
npm install --save-dev @nomiclabs/hardhat-ethers ethers @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-etherscan @nomiclabs/hardhat-solhint @nomiclabs/hardhat-ganache hardhat-docgen hardhat-spdx-license-identifier
```

### Add requirements in `hardhat.config.js`

```bash
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-solhint");
require("@nomiclabs/hardhat-ganache");
require("hardhat-docgen");
require("hardhat-spdx-license-identifier");
```

## use ganache
``npx hardhat --network ganache test``

## add docgen

````bash
docgen: {
  path: './docs',
  clear: true,
  runOnCompile: true,
}
````

The included Hardhat task may be run manually:

`yarn run hardhat docgen`

By default, the hardhat compile task is run before generating documentation. This behavior can be disabled with the `--no-compile flag`:

`yarn run hardhat docgen --no-compile`

The path directory will be created if it does not exist.

The clear option is set to `false` by default because it represents a destructive action, but should be set to `true` in most cases.

## add spdx-license-identifier

````bash
spdxLicenseIdentifier: {
  overwrite: true,
  runOnCompile: true,
}
````
