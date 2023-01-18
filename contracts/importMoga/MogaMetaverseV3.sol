//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../metaverse/Metaverse.sol";

contract MogaMetaverseV3 is Metaverse {
    function createAccountBatch(address[] calldata addrs, bool[] calldata isTrustAdmins) public onlyOwner {
        require(addrs.length == isTrustAdmins.length, "Metaverse: length is not match");
        require(addrs.length > 0, "Metaverse: length is zero");

        for (uint256 i = 0; i < addrs.length; i++) {
            core().createAccount_(addrs[i], addrs[i], isTrustAdmins[i]);
        }
    }
}
