//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IVChain.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Acert is Ownable {
    event SetVChain(address indexed vchain, string name, bool enabled);
    event RemarkAddress(address indexed addr, string remark, string class);

    mapping(address => bool) public vchainEnabled;
    mapping(address => string) public remarks;

    function setVChain(address _address, bool _enabled) public onlyOwner {
        vchainEnabled[_address] = _enabled;
        string memory name = IVChain(_address).name();
        emit SetVChain(_address, name, _enabled);
    }

    function remark(
        address _address,
        string calldata _remark,
        string calldata _class
    ) public onlyOwner {
        remarks[_address] = _remark;
        emit RemarkAddress(_address, _remark, _class);
    }
}
