//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../common/Ownable.sol";

contract MetaverseStorage is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private worlds;

    struct WorldInfo {
        address world;
        bool isEnabled;
    }

    struct Account {
        bool isExist;
        bool isTrustAdmin;
        bool isFreeze;
        uint256 id;
        address addr;
    }

    mapping(address => WorldInfo) public worldInfos;
    // Mapping from account ID to Account
    mapping(uint256 => Account) public accounts;
    // Mapping from adress to account ID
    mapping(address => uint256) public addressToId;
    // nonce
    mapping(address => uint256) public nonces;

    mapping(uint256 => mapping(address => bool)) public authAddress;

    mapping(address => uint256) public authToAddress;

    address public metaverse;

    constructor() {
        _owner = msg.sender;
    }

    function updateMetaverse(address addr) public onlyOwner {
        metaverse = addr;
    }

    modifier onlyMetaverse() {
        require( metaverse == msg.sender);
        _;
    }

    function IncrementNonce(address sender) public onlyMetaverse {
        nonces[sender]++;
    }

    function contains(address addr) public view returns (bool) {
        return worlds.contains(addr);
    }

    function add(address addr) public onlyMetaverse {
        if (!worlds.contains(addr)) {
            worlds.add(addr);
            worldInfos[addr] = WorldInfo(_world, true);
        }
    }

    function values() public view returns (address[] memory) {
        return worlds.values();
    }

    function length() public view returns (uint256) {
        return worlds.length();
    }

    function disableWorld(address addr) public onlyMetaverse {
        if (worlds.contains(addr)) {
            worldInfos[addr].isEnabled = false;
        }
    }

    function addAddressToId(address addr, uint256 id) public onlyMetaverse {
        addressToId[addr] = id;
    }

    function deleteAddressToId(address addr) public onlyMetaverse {
        delete addressToId[addr];
    }

    function setAccount(Account calldata account) public onlyMetaverse {
        accounts[account.id] = account;
    }

    function getWorldInfo(address addr) public view returns (WorldInfo memory) {
        return worldInfos[addr];
    }

    function getAccount(uint256 id) public view returns (Account memory) {
        return accounts[id];
    }

    function getAuthAddress(uint256 id) public view returns (address memory) {
        return authAddress[id];
    }

    function addAuthAddress(uint256 id, address  addr) public onlyMetaverse {
            authAddress[id][addr] = true;
            authToAddress[addr] = id;
    }

    function removeAuthAddress(uint256 id, address  addr) public onlyMetaverse {
            delete authAddress[id][addr];
            delete authToAddress[addr];
    }
}
