//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20, Ownable {
    constructor (string memory _name, string memory _symbol) public ERC20(_name, _symbol) {

    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
