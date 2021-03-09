//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { VerifySignature } from './utils/VerifySignature.sol';

contract MetaExchange is VerifySignature {
    mapping (bytes32 => bool) public fills;
    mapping (address => mapping(uint256 => bool)) public nonces;

    /****************************************
   *                EVENTS                *
   ****************************************/

    event MakerFilled(address indexed makerAddress,
        address indexed takerAddress,
        bytes32 orderHash,
        address[] makerErc20Addresses,
        uint256[] makerErc20Amounts,
        address[] makerErc721Addresses,
        uint256[] makerErc721Ids,
        address[] makerErc1155Addresses,
        uint256[] makerErc1155Ids,
        uint256[] makerErc1155Amounts);

    event TakerFilled(address indexed makerAddress,
        address indexed takerAddress,
        bytes32 orderHash,
        address[] takerErc20Addresses,
        uint256[] takerErc20Amounts,
        address[] takerErc721Addresses,
        uint256[] takerErc721Ids,
        address[] takerErc1155Addresses,
        uint256[] takerErc1155Ids,
        uint256[] takerErc1155Amounts);

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
        uint256[] makerErc721Ids;
        address[] makerErc1155Addresses;
        uint256[] makerErc1155Ids;
        uint256[] makerErc1155Amounts;
        address[] takerErc20Addresses;
        uint256[] takerErc20Amounts;
        address[] takerErc721Addresses;
        uint256[] takerErc721Ids;
        address[] takerErc1155Addresses;
        uint256[] takerErc1155Ids;
        uint256[] takerErc1155Amounts;
        uint256 expiration;
    }

    /****************************************
    *           PUBLIC FUNCTIONS           *
    ****************************************/


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
            order.makerErc20Addresses,
            order.makerErc20Amounts,
            order.makerErc721Addresses,
            order.makerErc721Ids,
            order.makerErc1155Addresses,
            order.makerErc1155Ids,
            order.makerErc1155Amounts,
            order.expiration,
            nonce,
            makerOrderSig)==true, "Maker Order Signature not valid");

        require(verify(
            makerAddress,
            order.takerErc20Addresses,
            order.takerErc20Amounts,
            order.takerErc721Addresses,
            order.takerErc721Ids,
            order.takerErc1155Addresses,
            order.takerErc1155Ids,
            order.takerErc1155Amounts,
            order.expiration,
            nonce,
            takerOrderSig)==true, "Taker Order Signature not valid");

        bytes32 orderHash = keccak256(abi.encodePacked(makerOrderSig, takerOrderSig));

        _fillOrder(order, makerAddress, takerAddress, orderHash);
        // Validate the message by signature.

        //trade erc721s

        //trade erc1155s


    }

    function cancelOrder() public {

    }

    /****************************************
    *          INTERNAL FUNCTIONS          *
    ****************************************/

    function _fillOrder(Order memory _order, address _makerAddress, address _takerAddress, bytes32 _orderHash) internal {

        uint i;

        //trade erc20s
        for (i=0; i<_order.makerErc20Addresses.length; i++) {
            IERC20(_order.makerErc20Addresses[i]).transferFrom(_makerAddress, _takerAddress, _order.makerErc20Amounts[i]);
        }

        for (i=0; i<_order.takerErc20Addresses.length; i++) {
            IERC20(_order.takerErc20Addresses[i]).transferFrom(_takerAddress, _makerAddress, _order.takerErc20Amounts[i]);
        }

        for (i=0; i<_order.makerErc721Addresses.length; i++) {
            IERC721(_order.makerErc721Addresses[i]).transferFrom(_makerAddress, _takerAddress, _order.makerErc721Ids[i]);
        }

        for (i=0; i<_order.takerErc721Addresses.length; i++) {
            IERC721(_order.takerErc721Addresses[i]).transferFrom(_takerAddress, _makerAddress, _order.takerErc721Ids[i]);
        }

        for (i=0; i<_order.makerErc1155Addresses.length; i++) {
            IERC1155(_order.makerErc1155Addresses[i]).safeTransferFrom(_makerAddress, _takerAddress, _order.makerErc1155Ids[i], _order.makerErc1155Amounts[i], "0x");
        }

        for (i=0; i<_order.takerErc1155Addresses.length; i++) {
            IERC1155(_order.takerErc1155Addresses[i]).safeTransferFrom(_takerAddress, _makerAddress, _order.takerErc1155Ids[i], _order.takerErc1155Amounts[i], "0x");
        }

        fills[_orderHash] = true;

        _emitMakerFilled(_order, _makerAddress, _takerAddress, _orderHash);
        _emitTakerFilled(_order, _makerAddress, _takerAddress, _orderHash);

    }


    //
    // !!! Split into 2 to avoid stack too deep error.
    //

    function _emitMakerFilled(Order memory _order, address _makerAddress, address _takerAddress, bytes32 _orderHash) internal {
        emit MakerFilled(_makerAddress,
            _takerAddress,
            _orderHash,
            _order.makerErc20Addresses,
            _order.makerErc20Amounts,
            _order.makerErc721Addresses,
            _order.makerErc721Ids,
            _order.makerErc1155Addresses,
            _order.makerErc1155Ids,
            _order.makerErc1155Amounts);
    }
    function _emitTakerFilled(Order memory _order, address _makerAddress, address _takerAddress, bytes32 _orderHash) internal {
        emit TakerFilled(_makerAddress,
            _takerAddress,
            _orderHash,
            _order.takerErc20Addresses,
            _order.takerErc20Amounts,
            _order.takerErc721Addresses,
            _order.takerErc721Ids,
            _order.takerErc1155Addresses,
            _order.takerErc1155Ids,
            _order.takerErc1155Amounts);
    }

}
