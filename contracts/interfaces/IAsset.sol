//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAsset {
    /**
     * @dev Returns the address of the world.
     */
    function worldAddress() external view returns (address);

    function changeAccountAddress(
        uint256 id,
        address newAddr
    ) external returns (bool);

    function getNonce(uint256 id) external view returns (uint256);
}
