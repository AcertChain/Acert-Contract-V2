// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Cash20.sol";

contract Cash20Mock is Cash20 {
    address private _owner;

    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        address world
    ) payable Cash20(name, symbol, version, world) {
        _owner = msg.sender;
    }

    function mint(address account, uint256 amount) public {
         onlyOwner();
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
         onlyOwner();
        _burn(account, amount);
    }

     function onlyOwner() internal view {
        require(_owner == msg.sender, "only owner");
    }
}