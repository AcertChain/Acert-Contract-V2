//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAsset {
    function worldAddress() external view returns (address);

    function changeAccountAddress(
        uint256 id,
        address newAddr,
        address oldAddr
    ) external returns (bool);

    function getNonce(uint256 id) external view returns (uint256);
}
