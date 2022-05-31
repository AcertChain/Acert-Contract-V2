//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IAsset.sol";

interface IWorldAsset is IAsset {
    function symbol() external view returns (string memory);

    function balanceOfId(uint256 owner) external view returns (uint256 balance);
}
