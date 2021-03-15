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

    event Canceled(address indexed makerAddress, address takerAddress, bytes32 orderHash, uint256 expiration, uint256 nonce);

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

        bytes32 orderHash = keccak256(abi.encodePacked(makerOrderSig, takerOrderSig));
        require(fills[orderHash] == false, "Order already filled or canceled by the maker");
        require(makerAddress != takerAddress, "Maker and taker should be different");
        require(order.expiration > now, "Order already expired and no longer valid");
        require(msg.sender != makerAddress, "Order cannot be executed by maker");
        require(msg.sender == takerAddress, "Only taker can execute the order");
        require(order.makerErc20Addresses.length == order.makerErc20Amounts.length,
            "Invalid Order, Size of erc20 address array and amounts different");
        require(order.makerErc721Addresses.length == order.makerErc721Ids.length,
            "Invalid Order, Size of erc721 address array and amounts different");
        require(order.makerErc1155Addresses.length == order.makerErc1155Ids.length
            && order.makerErc1155Addresses.length == order.makerErc1155Amounts.length,
            "Invalid Order, Size of erc1155 address array and amounts different");

        require(order.takerErc20Addresses.length == order.takerErc20Amounts.length,
            "Invalid Order, Size of erc20 address array and amounts different");
        require(order.takerErc721Addresses.length == order.takerErc721Ids.length,
            "Invalid Order, Size of erc721 address array and amounts different");
        require(order.takerErc1155Addresses.length == order.takerErc1155Ids.length
            && order.takerErc1155Addresses.length == order.takerErc1155Amounts.length,
            "Invalid Order, Size of erc1155 address array and amounts different");

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

        _fillOrder(order, makerAddress, takerAddress, orderHash);
    }

    function cancelOrder(address makerAddress,
        address takerAddress,
        Order memory order,
        bytes memory makerOrderSig,
        bytes memory takerOrderSig,
        uint256 nonce
        ) public {

        bytes32 orderHash = keccak256(abi.encodePacked(makerOrderSig, takerOrderSig));

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

        // Only the maker can cancel an order
        if (msg.sender == makerAddress) {

            require(fills[orderHash] == false, "Order already filled or cancelled");
            fills[orderHash] = true;
            emit Canceled(makerAddress, takerAddress, orderHash, order.expiration, nonce);

        }
    }

    /****************************************
    *          INTERNAL FUNCTIONS          *
    ****************************************/

    function _fillOrder(Order memory _order, address _makerAddress, address _takerAddress, bytes32 _orderHash) internal {

        uint i;

        fills[_orderHash] = true;

        //trade erc20s
        for (i=0; i<_order.makerErc20Addresses.length; i++) {
            require(_order.makerErc20Addresses[i] != address(0), "Invalid ERC20");
            IERC20(_order.makerErc20Addresses[i]).transferFrom(_makerAddress, _takerAddress, _order.makerErc20Amounts[i]);
        }

        for (i=0; i<_order.takerErc20Addresses.length; i++) {
            if (_order.takerErc20Addresses[i] == address(0)) {
                require(msg.value == _order.takerErc20Amounts[i], "Ether amount sent incorrect");
                address payable mkrAdress = address(uint160(_makerAddress));
                mkrAdress.transfer(msg.value);
            }
            else {
                IERC20(_order.takerErc20Addresses[i]).transferFrom(_takerAddress, _makerAddress, _order.takerErc20Amounts[i]);
            }

        }

        //trade erc721s
        for (i=0; i<_order.makerErc721Addresses.length; i++) {
            require(_order.makerErc721Addresses[i] != address(0), "Invalid ERC721");
            IERC721(_order.makerErc721Addresses[i]).transferFrom(_makerAddress, _takerAddress, _order.makerErc721Ids[i]);
        }

        for (i=0; i<_order.takerErc721Addresses.length; i++) {
            require(_order.takerErc721Addresses[i] != address(0), "Invalid ERC721");
            IERC721(_order.takerErc721Addresses[i]).transferFrom(_takerAddress, _makerAddress, _order.takerErc721Ids[i]);
        }

        //trade erc1155s
        for (i=0; i<_order.makerErc1155Addresses.length; i++) {
            require(_order.makerErc1155Addresses[i] != address(0), "Invalid ERC1155");
            IERC1155(_order.makerErc1155Addresses[i]).safeTransferFrom(_makerAddress, _takerAddress, _order.makerErc1155Ids[i], _order.makerErc1155Amounts[i], "0x");
        }

        for (i=0; i<_order.takerErc1155Addresses.length; i++) {
            require(_order.takerErc1155Addresses[i] != address(0), "Invalid ERC1155");
            IERC1155(_order.takerErc1155Addresses[i]).safeTransferFrom(_takerAddress, _makerAddress, _order.takerErc1155Ids[i], _order.takerErc1155Amounts[i], "0x");
        }

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
