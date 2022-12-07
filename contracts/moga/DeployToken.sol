// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Acert.sol";
import "../world/World.sol";
import "../world/WorldCore.sol";
import "./MogaToken.sol";
import "../token/Asset20.sol";
import "../token/Asset20Core.sol";
import "../token/Asset20Storage.sol";

contract DeployToken is Ownable {
    Acert public acert;

    constructor(address _acert) {
        acert = Acert(_acert);
    }

    function transferOwnership(address _contract, address _owner) public onlyOwner {
        Ownable(_contract).transferOwnership(_owner);
    }

    function createToken(
        address _world,
        string memory _tokenName,
        string memory _symbol
    ) public onlyOwner {
        World world = World(_world);
        string memory version = world.version();

        Asset20Storage assetStorage = new Asset20Storage();
        Asset20Core assetCore = new Asset20Core(_tokenName, _symbol, version, _world, address(assetStorage));
        Asset20 asset = new MogaToken_V3();

        assetStorage.updateAsset(address(assetCore));
        assetCore.updateShell(address(asset));
        asset.updateCore(address(assetCore));

        WorldCore worldCore = WorldCore(world.coreContract());
        worldCore.registerAsset(address(asset));

        string memory remark = acert.remarks(_world);
        acert.remark(address(asset), remark, "");
        acert.remark(address(assetCore), remark, "");
        acert.remark(address(assetStorage), remark, "");
    }
}
