//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract MockERC721 is ERC721, Ownable {
    constructor (string memory _name, string memory _symbol) public ERC721(_name, _symbol) {

    }

    function mint(address _to, uint256 _tokenId) public onlyOwner {
        _mint(_to, _tokenId);
    }
}
