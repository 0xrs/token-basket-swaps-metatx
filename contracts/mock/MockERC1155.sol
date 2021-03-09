//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155 } from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

contract MockERC1155 is ERC1155, Ownable {
    constructor (string memory _uri) public ERC1155(_uri) {

    }

    function mint(address _account, uint256 _id, uint256 _amount, bytes memory _data) public onlyOwner {
        _mint(_account, _id, _amount, _data);
    }
}
