// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Asset721.sol";
import "../interfaces/Mineable.sol";

contract MogaNFT_V3 is Asset721, Mineable {
    function mint(uint256 to, uint256 tokenId) public onlyMiner {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function safeMint(
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyMiner {
        _safeMint(to, tokenId, _data);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
