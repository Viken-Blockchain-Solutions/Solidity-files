# NFT Marketplace

## Mumbai Testnet Stats

### Deployment on Mumbai Testnet

- Deploying Marketplace with the account: 0x2fa005F3e5a5d35D431b7B8A1655d2CAc77f22AB

```bash
----------------------------------------------------------------------------------
|    Deployment Status  :
|       Contract owner  :           0x2fa005F3e5a5d35D431b7B8A1655d2CAc77f22AB
|
| ------------------------------------------------------------------------------
|   Contracts deployed  :
|       MarketPlace     :           0x3A48ef4751C892c9Ab52c46E3a185CCb8d34E530
|       MintableERC1155 :           0xCc239Ccb940ae1045B8670d8Ffcd0Ff7b8397771
----------------------------------------------------------------------------------
```

### Verification on Mumbai testnet

- MarketPlace verified

```bash
Compiling 1 file with 0.8.12
Successully submitted source code for contract
contracts/Nft/MarketPlace.sol:MarketPlace at 0x3A48ef4751C892c9Ab52c46E3a185CCb8d34E530
for verification on Polygonnscan. Waiting for verification result...

Successfully verified contract MarketPlace on Etherscan.
https://mumbai.polygonscan.com/address/0x3A48ef4751C892c9Ab52c46E3a185CCb8d34E530#code
```

- VikenERC1155 verified

```bash
Compiling 1 file with 0.8.12
Successfully submitted source code for contract
contracts/Nft/MintableERC1155.sol:MintableERC1155 at 0xCc239Ccb940ae1045B8670d8Ffcd0Ff7b8397771
for verification on Polygonscan. Waiting for verification result...

Successfully verified contract MintableERC1155 on Polygonscan.
https://mumbai.polygonscan.com/address/0xCc239Ccb940ae1045B8670d8Ffcd0Ff7b8397771#code
```  

### Dev-notes

- Naming of the json filed with token metadata has to follow the ERC1155 standard which is:
64 bytes padding. eks. `id 1` => `0000000000000000000000000000000000000000000000000000000000000001.json`.  

- In the ERC1155 `constructor() ERC1155("ADD_URI_HERE")`, we add the URI to the .json files like below.  

```js
ERC1155("https://xoovbqyg7wwx.usemoralis.com/collection/ERC1155/{id}.json")
```
