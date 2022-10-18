//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../moga/MogaMetaverse.sol";

contract ImportMogaMetaverseV1 is MogaMetaverse {
    constructor(
        string memory name_,
        string memory version_,
        uint256 startId_,
        address metaStorage_
    ) MogaMetaverse(name_, version_, startId_, metaStorage_) {}

    function createAccountBatch(address[] calldata addrs, bool[] calldata isTrustAdmins) public onlyOwner {
        require(addrs.length == isTrustAdmins.length, "Metaverse: length is not match");
        require(addrs.length > 0, "Metaverse: length is zero");

        for (uint256 i = 0; i < addrs.length; i++) {
            createAccount(addrs[i], isTrustAdmins[i]);
        }
    }
}
