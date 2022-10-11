// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Asset20.sol";

contract ImportMogaTokenV1 is Asset20 {
    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        address world,
        address storage_
    ) Asset20(name, symbol, version, world, storage_) {
    }

    function mint(uint256 accountId, uint256 amount) public onlyOwner {
        _mint(accountId, amount);
    }

    function burn(uint256 accountId, uint256 amount) public virtual onlyOwner {
        _burn(accountId, amount);
    }
}
