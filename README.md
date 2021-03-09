# Token Basket Swaps

### Overview

A maker can define a swap with multiple ERC20, ERC721 and/or ERC1155 tokens. The maker signs
the order for the taker to pick it up and the taker calls the `fill` function inside the MetaExchange
contract with signedHash by maker.

`MetaExchange` contract verifies that the order was indeed signed by the maker using utility functions
defined in the `VerifySignature.sol` contract. If the signature matches, a swap of the basket of
tokens is initiated by the MetaExchange.

Each filled order is saved in a mapping called `fills` with a key of `orderHash` which is derived using
`keccak256(abi.encodePacked(makerOrderSig, takerOrderSig))` where `makerOrderSig` and `takerOrderSig` are
signed hash messages using maker's private key with maker order tokens and taker order tokens as arguments.
They were split into separate hashes to avoid stack too deep error.

Since both `makerOrderSig` and `takerOrderSig` take nonce as an argument, once an orderHash is filled, the
same nonce cannot be used with the same order params. This is done to disallow a taker to execute the same signed
transaction multiple times and at the same time this design also allows the maker to create orders with the same params again
as the hash will change with the next nonce.

Each order also has an expiration timestamp after which the order is no longer valid.

### Instructions

```
npm i
npx hardhat test
```

### Output

![](docs/screenshot.png)
