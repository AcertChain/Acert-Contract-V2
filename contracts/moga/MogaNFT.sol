// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Asset721.sol";

contract MogaNFT is Asset721 {
    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        string memory tokenURI,
        address world,
        address storage_
    ) Asset721(name, symbol, version, tokenURI, world, storage_) {
        _owner = msg.sender;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function mint(uint256 to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        address owner = Asset721.ownerOf(tokenId);
        uint256 ownerId = _getAccountIdByAddress(owner);
        _checkSender(ownerId, _msgSender());
        _burn(tokenId, _msgSender());
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyOwner {
        _safeMint(to, tokenId, _data);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
