//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IMetaverse.sol";
import "../interfaces/IApplyStorage.sol";
import "../common/Ownable.sol";

contract Acert is Ownable {
    event SetMetaverse(address indexed metaverse, string name, address indexed storageAddress, bool enabled);

    mapping(address => bool) public metaverseEnabled;

    constructor() {
        _owner = msg.sender;
    }

    function setMetaverse(address _address, bool _enabled) public onlyOwner {
        metaverseEnabled[_address] = _enabled;
        string memory name = IMetaverse(_address).name();
        address storageAddress = IApplyStorage(_address).getStorageAddress();
        emit SetMetaverse(_address, name, storageAddress, _enabled);
    }
}
