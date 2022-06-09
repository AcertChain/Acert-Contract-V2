//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAsset {
    function worldAddress() external view returns (address);

    function getNonce(address account) external view returns (uint256);
}
