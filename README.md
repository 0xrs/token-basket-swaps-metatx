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

```
===================Deploying Contracts, Setting Up=====================
Maker Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Taker Address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Initial balance of ERC20 F1 for User1: 1000
Initial balance of ERC20 F1 for User2: 1000
Initial balance of ERC20 F2 for User1: 1000
Initial balance of ERC20 F2 for User2: 1000
Initial owner of ERC721 NFT1 ID1: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Initial owner of ERC721 NFT2 ID2: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Initial balance of ERC1155 NFT1 ID1 for User1: 10
Initial balance of ERC1155 NFT1 ID2 for User1: 0
Initial balance of ERC1155 NFT1 ID1 for User2: 0
Initial balance of ERC1155 NFT1 ID2 for User2: 10
Initial balance of ERC1155 NFT2 ID1 for User1: 10
Initial balance of ERC1155 NFT2 ID2 for User1: 0
Initial balance of ERC1155 NFT2 ID1 for User2: 0
Initial balance of ERC1155 NFT2 ID2 for User2: 10
=====================================================================


  Do a transaction of basket of assets of different types
    ✓ Should fail if transaction is made by maker (134ms)
    ✓ Should succeed if transaction is made by taker (295ms)
Final balance of ERC20 F1 for User1: 750
Final balance of ERC20 F1 for User2: 1250
Final balance of ERC20 F2 for User1: 1750
Final balance of ERC20 F2 for User2: 250
Final owner of ERC721 NFT1 ID1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Final owner of ERC721 NFT2 ID2: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Final balance of ERC1155 NFT1 ID1 for User1: 6
Final balance of ERC1155 NFT1 ID2 for User1: 0
Final balance of ERC1155 NFT1 ID1 for User2: 4
Final balance of ERC1155 NFT1 ID2 for User2: 10
Final balance of ERC1155 NFT2 ID1 for User1: 10
Final balance of ERC1155 NFT2 ID2 for User1: 2
Final balance of ERC1155 NFT2 ID1 for User2: 0
Final balance of ERC1155 NFT2 ID2 for User2: 8
    ✓ User balances should have updated values after swap (307ms)


  3 passing (5s)
  ```
