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

    function fill(address makerAddress,
        address takerAddress,
        address[] memory makerErc20Addresses,
        uint256[] memory makerErc20Amounts,
        address[] memory makerErc721Addresses,
        uint256[] memory makerErc721Amounts,
        //address[] memory makerErc1155Addresses,
        //uint256[] memory makerErc1155Amounts,
        address[] memory takerErc20Addresses,
        uint256[] memory takerErc20Amounts,
        address[] memory takerErc721Addresses,
        uint256[] memory takerErc721Amounts,
        //address[] memory takerErc1155Addresses,
        //uint256[] memory takerErc1155Amounts,
        uint256 expiration,
        uint256 nonce,
        bytes memory signedMsg
        //uint8 v,
        //bytes32 r,
        //bytes32 s
        )
    public {

        if (makerAddress == takerAddress) {
            /* msg.sender.transfer(msg.value);
            Failed(1,
            makerAddress, makerAmount, makerToken,
            takerAddress, takerAmount, takerToken,
            expiration, nonce); */
            return;
        }

        if (expiration < now) {
            /* msg.sender.transfer(msg.value);
            Failed(2,
                makerAddress, makerAmount, makerToken,
                takerAddress, takerAmount, takerToken,
                expiration, nonce); */
            return;
        }
        // Validate the message by signature.
        (bytes32 hash, bool validSig) = verify(makerAddress, makerAddress, takerAddress, makerErc20Addresses,
            makerErc20Amounts, takerErc20Addresses, takerErc20Amounts,
            expiration, nonce, signedMsg);
        require(validSig == true, "Signature not valid");

        if (fills[hash]) {
            /* msg.sender.transfer(msg.value);
            Failed(3,
                makerAddress, makerAmount, makerToken,
                takerAddress, takerAmount, takerToken,
                expiration, nonce); */
            return;
        }

        uint i;

        //trade erc20s
        for (i=0; i<makerErc20Addresses.length; i++) {
            IERC20(makerErc20Addresses[i]).transferFrom(makerAddress, takerAddress, makerErc20Amounts[i]);
        }

        for (i=0; i<takerErc20Addresses.length; i++) {
            IERC20(takerErc20Addresses[i]).transferFrom(takerAddress, makerAddress, takerErc20Amounts[i]);
        }

        //trade erc721s

        //trade erc1155s


    }

    function cancel() public {

    }

}
