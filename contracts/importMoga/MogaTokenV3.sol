// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../moga/MogaToken.sol";

contract MogaTokenV3 is MogaToken {
    function mintBatch(uint256[] calldata accountIds, uint256[] calldata amounts) public onlyOwner {
        require(accountIds.length == amounts.length, "MogaToken: accounts length not equal amounts length");
        for (uint256 i = 0; i < accountIds.length; i++) {
            _mint(accountIds[i], amounts[i]);
        }
    }
}
