//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../world/World.sol";
import "../interfaces/IMetaverse.sol";

contract MonsterGalaxyV3 is World {

    function trustWorldBatch(uint256[] calldata ids, bool[] calldata isTrusts) public onlyOwner {
        IMetaverse meta = IMetaverse(metaverseAddress());
        for (uint256 i = 0; i < ids.length; i++) {
            address sender = meta.getAddressByAccountId(ids[i]);
            core().trustWorld_(sender, ids[i], isTrusts[i]);
        }
    }
}
