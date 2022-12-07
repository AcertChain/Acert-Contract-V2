// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Acert.sol";
import "../world/World.sol";
import "../world/WorldCore.sol";
import "./MogaNFT.sol";
import "../token/Asset721.sol";
import "../token/Asset721Core.sol";
import "../token/Asset721Storage.sol";
import "../token/NFTMetadata.sol";

contract DeployNFT is Ownable {
    Acert public acert;

    constructor(address _acert) {
        acert = Acert(_acert);
    }

    function transferOwnership(address _contract, address _owner) public onlyOwner {
        Ownable(_contract).transferOwnership(_owner);
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
