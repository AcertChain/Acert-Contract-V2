//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IMetaverse.sol";
import "./interfaces/IApplyStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Acert is Ownable {
    event SetMetaverse(address indexed metaverse, string name, address indexed storageAddress, bool enabled);
    event RemarkAddress(address indexed adddr, string remark, string class);

    mapping(address => bool) public metaverseEnabled;
    mapping(address => string) public remarks;

    constructor() {
    }

    function setMetaverse(address _address, bool _enabled) public onlyOwner {
        metaverseEnabled[_address] = _enabled;
        string memory name = IMetaverse(_address).name();
        address storageAddress = IApplyStorage(_address).getStorageAddress();
        emit SetMetaverse(_address, name, storageAddress, _enabled);
    }

    function remark(address _address, string memory _remark, string memory _class) public onlyOwner {
        remarks[_address] = _remark;
        emit RemarkAddress(_address, _remark, _class);
    }
}
