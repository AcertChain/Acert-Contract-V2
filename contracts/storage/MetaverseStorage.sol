//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../common/Ownable.sol";

contract MetaverseStorage is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private worlds;

    struct WorldInfo {
        address world;
        string name;
        string icon;
        string url;
        string description;
        bool isEnabled;
    }

    struct Account {
        bool isExist;
        bool isTrustAdmin;
        bool isFreeze;
        uint256 id;
        address addr;
        address proxy;
    }

    mapping(address => WorldInfo) public worldInfos;
    // Mapping from account ID to Account
    mapping(uint256 => Account) public accounts;
    // Mapping from adress to account ID
    mapping(address => uint256) public addressToId;
    // nonce
    mapping(address => uint256) public nonces;

    uint256 public totalAccount;

    address public metaverse;

    constructor(address addr) {
        metaverse = addr;
        _owner = msg.sender;
    }

    function updateMetaverse(address addr) public onlyOwner {
        metaverse = addr;
    }

    modifier onlyMetaverse() {
        require(metaverse == msg.sender);
        _;
    }

    function IncrementTotalAccount() public onlyMetaverse {
        totalAccount++;
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
        }
    }

    function values() public view returns (address[] memory) {
        return worlds.values();
    }

    function length() public view returns (uint256) {
        return worlds.length();
    }

    function addWorldInfo(WorldInfo calldata info) public onlyMetaverse {
        worldInfos[info.world] = info;
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

    function addAccount(Account calldata account) public onlyMetaverse {
        accounts[account.id] = account;
    }

    function getWorldInfo(address addr) public view returns (WorldInfo memory) {
        return worldInfos[addr];
    }

    function getAccount(uint256 id) public view returns (Account memory) {
        return accounts[id];
    }
}
