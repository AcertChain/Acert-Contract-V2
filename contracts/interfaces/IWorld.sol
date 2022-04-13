//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWorld {
    function getOrCreateAccountID(address _address) external returns (uint256 id);
}
