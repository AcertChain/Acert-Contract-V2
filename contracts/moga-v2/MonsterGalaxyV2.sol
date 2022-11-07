//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../moga/MonsterGalaxy.sol";

contract MonsterGalaxyV2 is MonsterGalaxy {
    constructor(
        address metaverse_,
        address worldStorage_,
        string memory name_,
        string memory version_
    ) MonsterGalaxy(metaverse_, worldStorage_, name_, version_) {}

    function trustWorldBatch(uint256[] calldata _ids, bool _isTrustWorld) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            _trustWorld(_ids[i], _isTrustWorld, true, msg.sender);
        }
    }
}