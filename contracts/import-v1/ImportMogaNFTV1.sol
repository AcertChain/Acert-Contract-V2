// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../moga/MogaNFT.sol";

contract ImportMogaNFTV1 is MogaNFT {
    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        string memory tokenURI,
        address world,
        address storage_
    ) MogaNFT(name, symbol, version, tokenURI, world, storage_) {}

    function mintBatch(uint256[] calldata tos, uint256[][] calldata tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tos.length; i++) {
            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                _mint(tos[i], tokenIds[i][j]);
            }
        }
    }
}
