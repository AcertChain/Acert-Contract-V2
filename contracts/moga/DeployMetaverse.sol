// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Acert.sol";
import "../metaverse/Metaverse.sol";
import "../metaverse/MetaverseCore.sol";
import "../metaverse/MetaverseStorage.sol";

contract DeployMetaverse is Ownable {
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
}
