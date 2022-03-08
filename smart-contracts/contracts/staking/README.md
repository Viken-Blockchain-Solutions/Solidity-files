
# TicketVault - ERC20 Staking Contract

TicketVault is a Vault smart-contract written in Solidity. With TicketVault any project can reward their token holders by offering "Staking" for a preset time period.

[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/tterb/atomic-design-ui/blob/master/LICENSEs)

---

## TicketVault features

Admin features:

- Set custom vault stake period.
- Set custom ERC20 and amount to reward the users.
- Deposit the total amount to be rewarded.
- Set the withdraw fee address.
- Set the withdraw fee percentage.

User features:

- Can deposit into vault to stake.
- Can exit their position at any time.
- Earn rewards for staking set ERC20.

## Documentation

[Documentation](https://github.com/CentaurifyOrg/smart_contracts/blob/main/contracts/Staking/TicketVault_docs.md)

## Run Locally

Clone the project:

```bash
  git clone https://github.com/CentaurifyOrg/smart_contracts.git
```

Go to the project directory:

```bash
  cd smart-contracts
```

Install dependencies:

```bash
  yarn
```

Compile smart-contracts:

```bash
  yarn compile
```

## Running Tests

### To run tests, run the following commands below

Start ganache-cli local server:

```bash
  yarn ganache
```

Open a new tab and run to deploy contracts locally:

```bash
  yarn deploy_local
```

Run tests:

```bash
  yarn test_local
```

## Tech Stack

**Client:** Hardhat

**Server:** Node, Ganache, Alchemy

## Authors
- [Viken Blockchain Solutions](https://www.vikenblockchain.com)
  - [@Dadogg80](https://www.github.com/dadogg80)

## Feedback

If you have any feedback, please reach out to us at contact@vikenblockchain.com

## License

[MIT](https://choosealicense.com/licenses/mit/)
