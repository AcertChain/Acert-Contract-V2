//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAsset {
    enum ProtocolEnum {
        ASSET20,
        ASSET721
    }

    function protocol() external view returns (ProtocolEnum);

    function getNonce(address account) external view returns (uint256);
}
