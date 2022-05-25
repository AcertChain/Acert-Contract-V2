// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Item721.sol";
import "../common/Ownable.sol";

contract Item721Mock is Item721, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        address world
    ) Item721(name, symbol, version, world) {
        _owner = msg.sender;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId)  public onlyOwner {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner{
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyOwner {
        _safeMint(to, tokenId, _data);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
