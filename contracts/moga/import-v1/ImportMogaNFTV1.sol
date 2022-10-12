// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/Asset721.sol";

contract ImportMogaNFTV1 is Asset721 {
    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        string memory tokenURI,
        address world,
        address storage_
    ) Asset721(name, symbol, version, tokenURI, world, storage_) {
    }

    function mint(uint256 to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual onlyOwner {
        _burn(tokenId);
    }

}
