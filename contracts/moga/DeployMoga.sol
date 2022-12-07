// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Acert.sol";
import "../metaverse/Metaverse.sol";
import "../metaverse/MetaverseCore.sol";
import "../metaverse/MetaverseStorage.sol";
import "../world/World.sol";
import "../world/WorldCore.sol";
import "../world/WorldStorage.sol";
import "./MogaToken.sol";
import "../token/Asset20.sol";
import "../token/Asset20Core.sol";
import "../token/Asset20Storage.sol";
import "./MogaNFT.sol";
import "../token/Asset721.sol";
import "../token/Asset721Core.sol";
import "../token/Asset721Storage.sol";
import "../token/NFTMetadata.sol";

contract DeployMoga is Ownable {
    Acert public acert;

    constructor(address _acert) {
        acert = Acert(_acert);
    }

    function transferOwnership(address _contract, address _owner) public onlyOwner {
        Ownable(_contract).transferOwnership(_owner);
    }

    function createMetaverse(address _metaCore, string memory _remark) public onlyOwner {
        MetaverseStorage metaStorage = new MetaverseStorage();
        MetaverseCore metaCore = MetaverseCore(_metaCore);
        Metaverse metaverse = new Metaverse();

        metaStorage.updateMetaverse(_metaCore);
        metaCore.updateShell(address(metaverse));
        metaverse.updateCore(_metaCore);

        acert.setMetaverse(address(metaverse), true);

        acert.remark(address(metaverse), _remark, "");
        acert.remark(_metaCore, _remark, "");
        acert.remark(address(metaStorage), _remark, "");
    }

    function createWorld(address _metaverse, string memory _worldName) public onlyOwner {
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

    function createNFT(
        address _world,
        string memory _tokenName,
        string memory _tokenURI,
        string memory _symbol
    ) public onlyOwner {
        World world = World(_world);
        string memory version = world.version();

        Asset721Storage assetStorage = new Asset721Storage();
        Asset721Core assetCore = new Asset721Core(
            _tokenName,
            _symbol,
            version,
            _tokenURI,
            _world,
            address(assetStorage)
        );
        Asset721 asset = new Asset721();
        NFTMetadata metadata = new NFTMetadata(address(assetStorage));

        assetStorage.updateNFTMetadataContract(address(metadata));
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
