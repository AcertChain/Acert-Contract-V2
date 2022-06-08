//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./common/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Metaverse is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private worlds;

    event AddWorld(
        address indexed world,
        string name,
        string icon,
        string url,
        string description
    );
    event UpdateWorld(
        address indexed world,
        string name,
        string icon,
        string url,
        string description
    );
    event RemoveWorld(address indexed world);

    mapping(address => WorldInfo) private worldInfos;

    struct WorldInfo {
        address world;
        string name;
        string icon;
        string url;
        string description;
    }

    constructor() {
        _owner = msg.sender;
    }

    function addWorld(
        address _world,
        string calldata _name,
        string calldata _icon,
        string calldata _url,
        string calldata _description
    ) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        if (!worlds.contains(_world)) {
            worlds.add(_world);
            worldInfos[_world] = WorldInfo({
                world: _world,
                name: _name,
                icon: _icon,
                url: _url,
                description: _description
            });
            emit AddWorld(_world,_name,_icon,_url,_description);
        }
    }

    function removeWorld(address _world) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        if (worlds.contains(_world)) {
            worlds.remove(_world);
            emit RemoveWorld(_world);
        }
    }

    function updateWorldInfo(
        address _world,
        string calldata _name,
        string calldata _icon,
        string calldata _url,
        string calldata _description
    ) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        if (worlds.contains(_world)) {
            worldInfos[_world] = WorldInfo({
                world: _world,
                name: _name,
                icon: _icon,
                url: _url,
                description: _description
            });
            emit UpdateWorld(_world,_name,_icon,_url,_description);
        }
    }

    function getWorldInfo(address _world)
        public
        view
        returns (WorldInfo memory info)
    {
        if (worlds.contains(_world)) {
            info = worldInfos[_world];
        }
    }

    function containsWorld(address _world) public view returns (bool) {
        return worlds.contains(_world);
    }

    function getWorlds() public view returns (address[] memory) {
        return worlds.values();
    }

    function getWorldCount() public view returns (uint256) {
        return worlds.length();
    }
}
