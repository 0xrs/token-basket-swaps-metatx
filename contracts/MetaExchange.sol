//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { VerifySignature } from './utils/VerifySignature.sol';

contract MetaExchange is VerifySignature {
    mapping (bytes32 => bool) public fills;
    mapping (address => mapping(uint256 => bool)) public nonces;
    /* event Filled(address indexed makerAddress, uint makerAmount, address indexed makerToken, address takerAddress, uint takerAmount, address indexed takerToken, uint256 expiration, uint256 nonce); */
    /* event Canceled(address indexed makerAddress, uint makerAmount, address indexed makerToken, address takerAddress, uint takerAmount, address indexed takerToken, uint256 expiration, uint256 nonce); */

    /** Event thrown when a trade fails
      * Error codes:
      * 1 -> 'The makeAddress and takerAddress must be different',
      * 2 -> 'The order has expired',
      * 3 -> 'This order has already been filled',
      * 4 -> 'The ether sent with this transaction does not match takerAmount',
      * 5 -> 'No ether is required for a trade between tokens',
      * 6 -> 'The sender of this transaction must match the takerAddress',
      * 7 -> 'Order has already been cancelled or filled'
      */
    /* event Failed(uint code, address indexed makerAddress, uint makerAmount, address indexed makerToken, address takerAddress, uint takerAmount, address indexed takerToken, uint256 expiration, uint256 nonce); */
    struct Order {
        address[] makerErc20Addresses;
        uint256[] makerErc20Amounts;
        address[] makerErc721Addresses;
        uint256[] makerErc721Amounts;
        address[] makerErc1155Addresses;
        uint256[] makerErc1155Amounts;
        address[] takerErc20Addresses;
        uint256[] takerErc20Amounts;
        address[] takerErc721Addresses;
        uint256[] takerErc721Amounts;
        address[] takerErc1155Addresses;
        uint256[] takerErc1155Amounts;
        uint256 expiration;
    }

    function fill(address makerAddress,
        address takerAddress,
        Order memory order,
        bytes memory makerOrderSig,
        bytes memory takerOrderSig,
        uint256 nonce
        )
    public {

        require(verify(
            makerAddress,
            takerAddress,
            order.makerErc20Addresses,
            order.makerErc20Amounts,
            order.makerErc721Addresses,
            order.makerErc721Amounts,
            order.makerErc1155Addresses,
            order.makerErc1155Amounts,
            order.expiration,
            nonce,
            makerOrderSig)==true, "Maker Order Signature not valid");

        require(verify(
            makerAddress,
            takerAddress,
            order.takerErc20Addresses,
            order.takerErc20Amounts,
            order.takerErc721Addresses,
            order.takerErc721Amounts,
            order.takerErc1155Addresses,
            order.takerErc1155Amounts,
            order.expiration,
            nonce,
            takerOrderSig)==true, "Taker Order Signature not valid");
        // Validate the message by signature.

        uint i;

        //trade erc20s
        for (i=0; i<order.makerErc20Addresses.length; i++) {
            IERC20(order.makerErc20Addresses[i]).transferFrom(makerAddress, takerAddress, order.makerErc20Amounts[i]);
        }

        for (i=0; i<order.takerErc20Addresses.length; i++) {
            IERC20(order.takerErc20Addresses[i]).transferFrom(takerAddress, makerAddress, order.takerErc20Amounts[i]);
        }

        //trade erc721s

        //trade erc1155s


    }

    function cancel() public {

    }

}
