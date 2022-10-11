//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IMetaverse.sol";
import "../common/Ownable.sol";

contract Acert is Ownable {
    event SetMetaverse(address indexed metaverse, bool enabled);

    mapping(address => bool) public MetaverseEnabled;

    constructor() {
    }

    function setMetaverse(address _address, bool _enabled) public onlyOwner {
        
        MetaverseEnabled[_address] = _enabled;
        emit RegisterWorld(_world, _name);

    }
