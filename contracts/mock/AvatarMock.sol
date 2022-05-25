// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/Item721.sol";
import "../common/Ownable.sol";

contract AvatarMock is Item721, Ownable {
    uint256 private _supply;
    uint256 private _maxAvatarId;

    constructor(
        uint256 supply,
        uint256 maxAvatarId,
        string memory name,
        string memory symbol,
        string memory version,
        address world
    ) Item721(name, symbol, version, world) {
        _supply = supply;
        _maxAvatarId = maxAvatarId;
        _owner = msg.sender;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _supply;
    }

    function maxAvatar() public view virtual returns (uint256) {
        return _maxAvatarId;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    modifier checkOwnerAndTokenId(uint256 tokenId) {
        require(_owner == msg.sender, "only owner");
        require(
            _maxAvatarId >= tokenId && tokenId != 0,
            "tokenId can't bigger than maxAvatarId"
        );
        _;
    }

    function mint(address to, uint256 tokenId)
        public
        checkOwnerAndTokenId(tokenId)
    {
        _mint(to, tokenId);
        _supply++;
    }

    function safeMint(address to, uint256 tokenId)
        public
        checkOwnerAndTokenId(tokenId)
    {
        _safeMint(to, tokenId);
        _supply++;
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public checkOwnerAndTokenId(tokenId) {
        _safeMint(to, tokenId, _data);
        _supply++;
    }

    function burn(uint256 tokenId) public checkOwnerAndTokenId(tokenId) {
        _burn(tokenId);
        _supply--;
    }
}
