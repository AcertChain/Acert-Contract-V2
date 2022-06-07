//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./common/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Metaverse is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private worlds;

    event AddWorld(address indexed world);
    event RemoveWorld(address indexed world);

    constructor() {
        _owner = msg.sender;
    }

    function addWorld(address _world) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        if (!worlds.contains(_world)) {
            worlds.add(_world);
            emit AddWorld(_world);
        }
    }

    function removeWorld(address _world) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        if (worlds.contains(_world)) {
            worlds.remove(_world);
            emit RemoveWorld(_world);
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
