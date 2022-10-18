// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../moga/MogaToken.sol";

contract ImportMogaTokenV1 is MogaToken {
    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        address world,
        address storage_
    ) MogaToken(name, symbol, version, world, storage_) {}

    function mintBatch(uint256[] calldata accountIds, uint256[] calldata amounts) public onlyOwner {
        require(accountIds.length == amounts.length, "MogaToken: accounts length not equal amounts length");
        for (uint256 i = 0; i < accountIds.length; i++) {
            _mint(accountIds[i], amounts[i]);
        }
    }
}
