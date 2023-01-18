// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../moga/MogaNFT.sol";

contract MogaNFTV3 is MogaNFT {

    function mintBatch(uint256[] calldata tos, uint256[][] calldata tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tos.length; i++) {
            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                _mint(tos[i], tokenIds[i][j]);
            }
        }
    }
}
