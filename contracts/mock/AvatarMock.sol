// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Item721.sol";

contract AvatarMock is Item721 {
    uint256 private _supply;
    address private _owner;

    constructor(
        uint256 supply,
        string memory name,
        string memory symbol,
        string memory version,
        address world
    ) Item721(name, symbol, version, world) {
        _supply = supply;
        _owner = msg.sender;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _supply;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId) public {
        onlyOwnerAndLessSupply(tokenId);
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public {
        onlyOwnerAndLessSupply(tokenId);
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        onlyOwnerAndLessSupply(tokenId);
        _safeMint(to, tokenId, _data);
    }

    function burn(uint256 tokenId) public {
        onlyOwnerAndLessSupply(tokenId);
        _burn(tokenId);
    }

    function onlyOwnerAndLessSupply(uint256 tokenId) internal view {
        require(_owner == msg.sender, "only owner");
        require(_supply >= tokenId, "bigger than supply");
    }
}
