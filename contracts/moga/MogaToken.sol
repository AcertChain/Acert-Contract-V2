// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Asset20.sol";

contract GGMToken is Asset20 {
    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        address world,
        address storage_
    ) Asset20(name, symbol, version, world, storage_) {
        _owner = msg.sender;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function mint(uint256 accountId, uint256 amount) public onlyOwner {
        _mint(accountId, amount);
    }

    function burn(uint256 accountId, uint256 amount) public onlyOwner {
        _burn(accountId, amount);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
