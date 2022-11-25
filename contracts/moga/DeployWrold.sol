// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Acert.sol";
import "../metaverse/Metaverse.sol";
import "../metaverse/MetaverseCore.sol";
import "../world/World.sol";
import "../world/WorldCore.sol";
import "../world/WorldStorage.sol";

contract DeployWorld is Ownable {

    Acert public acert;
    
    constructor(address _acert) {
        acert = Acert(_acert);
    }
    
    function transferOwnership(address _contract, address _owner) public onlyOwner {
        Ownable(_contract).transferOwnership(_owner);
    }

    function createWorld(
        address _metaverse,
        string memory _worldName
    ) public onlyOwner {
        Metaverse metaverse = Metaverse(_metaverse);
        string memory version = metaverse.version();

        WorldStorage worldStorage = new WorldStorage();
        WorldCore worldCore = new WorldCore(_worldName, version, _metaverse, address(worldStorage));
        World world = new World();

        worldStorage.updateWorld(address(worldCore));
        worldCore.updateShell(address(world));
        world.updateCore(address(worldCore));

        MetaverseCore metaCore = MetaverseCore(metaverse.coreContract());
        metaCore.registerWorld(address(world));

        string memory remark = acert.remarks(_metaverse);
        acert.remark(address(world), remark, "");
        acert.remark(address(worldCore), remark, "");
        acert.remark(address(worldStorage), remark, "");
    }
}
