# Token Basket Swaps

### Overview

A maker can define a swap with multiple ERC20, ERC721 and/or ERC1155 tokens. The maker signs
the order for the taker to pick it up and the taker calls the `fill` function inside the MetaExchange
contract with signedHash by maker.

`MetaExchange` contract verifies that the order was indeed signed by the maker using utility functions
defined in the `VerifySignature.sol` contract. If the signature matches, a swap of the basket of
tokens is initiated by the MetaExchange.


### Glossary

`makerAddress`:

`takerAddress`:

`orderHash`:

`nonce`:



```
npm i
npx hardhat test
```

![](docs/screenshot.png)
