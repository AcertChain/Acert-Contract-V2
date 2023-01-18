// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Asset20.sol";
import "../interfaces/Mineable.sol";

contract MogaToken is Asset20, Mineable {
    function mint(uint256 accountId, uint256 amount) public onlyMiner {
        _mint(accountId, amount);
    }

    function burn(uint256 accountId, uint256 amount) public onlyMiner {
        _burn(accountId, amount);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
