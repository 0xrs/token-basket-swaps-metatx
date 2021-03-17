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
    Order private order;
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
        bytes memory _order,
        bytes memory orderSig,
        uint256 nonce
        )
    public payable {
        bytes32[] memory _data = bytesToBytes32Array(_order);
        bytes32 orderHash = keccak256(orderSig);
        delete order;
        uint256 i = uint256(_data[0])/32-1;
        order.expiration = uint256(_data[i]);

        for (i=uint256(_data[0])/32+1; i<uint256(_data[1])/32; i++) {
            order.makerErc20Addresses.push(address(uint160(uint256(_data[i]))));
        }

        for (i=uint256(_data[1])/32+1; i<uint256(_data[2])/32; i++) {
            order.makerErc20Amounts.push(uint256(_data[i]));
        }

        for (i=uint256(_data[2])/32+1; i<uint256(_data[3])/32; i++) {
            order.makerErc721Addresses.push(address(uint160(uint256(_data[i]))));
        }

        for (i=uint256(_data[3])/32+1; i<uint256(_data[4])/32; i++) {
            order.makerErc721Ids.push(uint256(_data[i]));
        }

        for (i=uint256(_data[4])/32+1; i<uint256(_data[5])/32; i++) {
            order.makerErc1155Addresses.push(address(uint160(uint256(_data[i]))));
        }

        for (i=uint256(_data[5])/32+1; i<uint256(_data[6])/32; i++) {
            order.makerErc1155Ids.push(uint256(_data[i]));
        }

        for (i=uint256(_data[6])/32+1; i<uint256(_data[7])/32; i++) {
            order.makerErc1155Amounts.push(uint256(_data[i]));
        }

        for (i=uint256(_data[7])/32+1; i<uint256(_data[8])/32; i++) {
            order.takerErc20Addresses.push(address(uint160(uint256(_data[i]))));
        }

        for (i=uint256(_data[8])/32+1; i<uint256(_data[9])/32; i++) {
            order.takerErc20Amounts.push(uint256(_data[i]));
        }

        for (i=uint256(_data[9])/32+1; i<uint256(_data[10])/32; i++) {
            order.takerErc721Addresses.push(address(uint160(uint256(_data[i]))));
        }

        for (i=uint256(_data[10])/32+1; i<uint256(_data[11])/32; i++) {
            order.takerErc721Ids.push(uint256(_data[i]));
        }

        for (i=uint256(_data[11])/32+1; i<uint256(_data[12])/32; i++) {
            order.takerErc1155Addresses.push(address(uint160(uint256(_data[i]))));
        }

        for (i=uint256(_data[12])/32+1; i<uint256(_data[13])/32; i++) {
            order.takerErc1155Ids.push(uint256(_data[i]));
        }

        for (i=uint256(_data[13])/32+1; i<uint256(_data[13])/32+1+order.takerErc1155Ids.length; i++) {
            order.takerErc1155Amounts.push(uint256(_data[i]));
        }

        require(verify(makerAddress, _order, order.expiration, nonce, orderSig) == true, "Order Signature not valid");

        fills[orderHash] = true;

        //trade erc20s
        for (i=0; i<order.makerErc20Addresses.length; i++) {
            require(order.makerErc20Addresses[i] != address(0), "Invalid ERC20");
            IERC20(order.makerErc20Addresses[i]).transferFrom(makerAddress, takerAddress, order.makerErc20Amounts[i]);
        }

        for (i=0; i<order.takerErc20Addresses.length; i++) {
            if (order.takerErc20Addresses[i] == address(0)) {
                require(msg.value == order.takerErc20Amounts[i], "Ether amount sent incorrect");
                address payable mkrAdress = address(uint160(makerAddress));
                mkrAdress.transfer(msg.value);
            }
            else {
                IERC20(order.takerErc20Addresses[i]).transferFrom(takerAddress, makerAddress, order.takerErc20Amounts[i]);
            }

        }

        //trade erc721s
        for (i=0; i<order.makerErc721Addresses.length; i++) {
            require(order.makerErc721Addresses[i] != address(0), "Invalid ERC721");
            IERC721(order.makerErc721Addresses[i]).transferFrom(makerAddress, takerAddress, order.makerErc721Ids[i]);
        }

        for (i=0; i<order.takerErc721Addresses.length; i++) {
            require(order.takerErc721Addresses[i] != address(0), "Invalid ERC721");
            IERC721(order.takerErc721Addresses[i]).transferFrom(takerAddress, makerAddress, order.takerErc721Ids[i]);
        }

        //trade erc1155s
        for (i=0; i<order.makerErc1155Addresses.length; i++) {
            require(order.makerErc1155Addresses[i] != address(0), "Invalid ERC1155");
            IERC1155(order.makerErc1155Addresses[i]).safeTransferFrom(makerAddress, takerAddress, order.makerErc1155Ids[i], order.makerErc1155Amounts[i], "0x");
        }

        for (i=0; i<order.takerErc1155Addresses.length; i++) {
            require(order.takerErc1155Addresses[i] != address(0), "Invalid ERC1155");
            IERC1155(order.takerErc1155Addresses[i]).safeTransferFrom(takerAddress, makerAddress, order.takerErc1155Ids[i], order.takerErc1155Amounts[i], "0x");
        }

        emit MakerFilled(makerAddress,
            takerAddress,
            orderHash,
            order.makerErc20Addresses,
            order.makerErc20Amounts,
            order.makerErc721Addresses,
            order.makerErc721Ids,
            order.makerErc1155Addresses,
            order.makerErc1155Ids,
            order.makerErc1155Amounts);


        emit TakerFilled(makerAddress,
            takerAddress,
            orderHash,
            order.takerErc20Addresses,
            order.takerErc20Amounts,
            order.takerErc721Addresses,
            order.takerErc721Ids,
            order.takerErc1155Addresses,
            order.takerErc1155Ids,
            order.takerErc1155Amounts);
    }

    /****************************************
    *          INTERNAL FUNCTIONS          *
    ****************************************/


    function bytesToBytes32Array(bytes memory data) internal pure
    returns (bytes32[] memory) {
        // Find 32 bytes segments nb
        uint256 dataNb = data.length / 32;
        // Create an array of dataNb elements
        bytes32[] memory dataList = new bytes32[](dataNb);
        // Start array index at 0
        uint256 index = 0;
        // Loop all 32 bytes segments
        for (uint256 i = 32; i <= data.length; i = i + 32) {
            bytes32 temp;
            // Get 32 bytes from data
            assembly {
                temp := mload(add(data, i))
            }
            // Add extracted 32 bytes to list
            dataList[index] = temp;
            index++;
        }
        // Return data list
        return (dataList);
    }

}
