//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IAsset.sol";

interface IWorldAsset is IAsset {
     enum ProtocolEnum {
        CASH20,
        ITEM721
    }

    function symbol() external view returns (string memory);

    function protocol() external pure returns (ProtocolEnum);
}
