// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Cash20.sol";
import "../common/Ownable.sol";

contract Cash20Mock is Cash20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        address world
    )  Cash20(name, symbol, version, world) {
        _owner = msg.sender;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function mintCash(uint256 accountId, uint256 amount) public onlyOwner {
        _mintCash(accountId, amount);
    }

    function burnCash(uint256 accountId, uint256 amount) public onlyOwner {
        _burnCash(accountId, amount);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}