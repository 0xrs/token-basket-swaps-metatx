//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { VerifySig } from './VerifySig.sol';

contract Exchange is VerifySig {
    mapping (bytes32 => bool) public fills;
    uint8 internal constant SWAP_ERC20 = 1;
    uint8 internal constant SWAP_ERC20_WITH_PERMIT = 2;
    uint8 internal constant SWAP_ERC721 = 3;
    uint8 internal constant SWAP_ERC1155 = 4;

    /****************************************
    *           PUBLIC FUNCTIONS           *
    ****************************************/


    function fill(
        address maker,
        address taker,
        uint8[] memory actions,
        bytes[] memory orders,
        bytes memory orderSig,
        uint256 nonce,
        uint256 expiration
    ) public {
        require(msg.sender == taker, "Only taker can execute the order");
        require(taker != maker, "Maker cant be the same as taker");
        require(fills[keccak256(orderSig)] == false, "Order already filled");

        //verify sig
        require(verify(maker, actions, orders, nonce, expiration, orderSig), "Order signature not valid");

        fills[keccak256(orderSig)] = true;

        for (uint256 i=0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (action == SWAP_ERC20) {
                _swapERC20(orders[i], maker, taker);
            }
            /* if (action == SWAP_ERC20_WITH_PERMIT) {
                _swapERC20WithPermit(orders[i], maker, taker);
            } */
            if (action == SWAP_ERC721) {
                _swapERC721(orders[i], maker, taker);
            }
            if (action == SWAP_ERC1155) {
                _swapERC1155(orders[i], maker, taker);
            }
        }
    }


    /****************************************
    *          INTERNAL FUNCTIONS          *
    ****************************************/

    function _swapERC20(bytes memory order, address maker, address taker) internal {
        (bool[] memory directions, address[] memory tokenAddresses, uint256[] memory amounts) = abi.decode(order, (bool[], address[], uint256[]));
        require((directions.length == tokenAddresses.length) && (directions.length == amounts.length), "Invalid ERC20 Swap Args");
        for (uint256 i=0; i<directions.length; i++) {
            if (directions[i]) {
                require(tokenAddresses[i] != address(0), "Invalid ERC20");
                IERC20(tokenAddresses[i]).transferFrom(maker, taker, amounts[i]);
            }
            else {
                if (tokenAddresses[i] == address(0)) {
                    require(msg.value == amounts[i], "Ether amount sent incorrect");
                    address payable mkrAddress = address(uint160(maker));
                    mkrAddress.transfer(msg.value);
                }
                else {
                    IERC20(tokenAddresses[i]).transferFrom(taker, maker, amounts[i]);
                }
            }
        }
    }

    /* function _swapERC20WithPermit(bytes memory order, address maker, address taker) internal {
        (bool[] memory directions, address[] memory tokenAddresses, uint256[] memory amounts, bytes[] memory permitSigs) = abi.decode(order, (bool[], address[], uint256[], bytes[]));
        require((directions.length == tokenAddresses.length) && (directions.length == amounts.length), "Invalid ERC20 Swap Args");
        for (uint256 i=0; i<directions.length; i++) {
            if (directions[i]) {
                require(tokenAddresses[i] != address(0), "Invalid ERC20");
                IERC20(tokenAddresses[i]).transferFrom(maker, taker, amounts[i]);
            }
            else {
                IERC20(tokenAddresses[i]).transferFrom(taker, maker, amounts[i]);
            }
        }
    } */

    function _swapERC721(bytes memory order, address maker, address taker) internal {
        (bool[] memory directions, address[] memory tokenAddresses, uint256[] memory ids) = abi.decode(order, (bool[], address[], uint256[]));
        require((directions.length == tokenAddresses.length) && (directions.length == ids.length), "Invalid ERC721 Swap Args");
        for (uint256 i=0; i<directions.length; i++) {
            require(tokenAddresses[i] != address(0), "Invalid ERC721");
            if (directions[i]) {
                IERC721(tokenAddresses[i]).transferFrom(maker, taker, ids[i]);
            }
            else {
                IERC721(tokenAddresses[i]).transferFrom(taker, maker, ids[i]);
            }
        }
    }

    function _swapERC1155(bytes memory order, address maker, address taker) internal {
        (bool[] memory directions, address[] memory tokenAddresses, uint256[] memory ids, uint256[] memory amounts) = abi.decode(order, (bool[], address[], uint256[], uint256[]));
        require((directions.length == tokenAddresses.length) && (directions.length == ids.length) && (directions.length == amounts.length), "Invalid ERC1155 Swap Args");
        for (uint256 i=0; i<directions.length; i++) {
            require(tokenAddresses[i] != address(0), "Invalid ERC1155");
            if (directions[i]) {
                IERC1155(tokenAddresses[i]).safeTransferFrom(maker, taker, ids[i], amounts[i], "0x");
            }
            else {
                IERC1155(tokenAddresses[i]).safeTransferFrom(taker, maker, ids[i], amounts[i], "0x");
            }
        }
    }

}
