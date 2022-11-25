//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IMetaverse.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Acert is Ownable {
    event SetMetaverse(address indexed metaverse, string name, bool enabled);
    event RemarkAddress(address indexed addr, string remark, string class);

    mapping(address => bool) public metaverseEnabled;
    mapping(address => string) public remarks;

    function setMetaverse(address _address, bool _enabled) public onlyOwner {
        metaverseEnabled[_address] = _enabled;
        string memory name = IMetaverse(_address).name();
        emit SetMetaverse(_address, name, _enabled);
    }

    function remark(address _address, string memory _remark, string memory _class) public onlyOwner {
        remarks[_address] = _remark;
        emit RemarkAddress(_address, _remark, _class);
    }
}
