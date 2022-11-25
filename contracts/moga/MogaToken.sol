// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Asset20.sol";
import "../interfaces/Mineable.sol";

contract MogaToken_V3 is Asset20, Mineable {

    function mint(uint256 accountId, uint256 amount) public onlyMiner {
        _mint(accountId, amount);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
