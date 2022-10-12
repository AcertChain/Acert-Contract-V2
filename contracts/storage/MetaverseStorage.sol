//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../common/Ownable.sol";

interface IMetaverseName {
    function initName() external view returns (string memory);
    function startId() external view returns (uint256);
}

contract MetaverseStorage is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private worlds;

    struct WorldInfo {
        address world;
        string name;
        bool isEnabled;
    }

    struct Account {
        bool isExist;
        bool isTrustAdmin;
        bool isFreeze;
        uint256 id;
    }

    mapping(address => WorldInfo) public worldInfos;
    // Mapping from account ID to Account
    mapping(uint256 => Account) public accounts;
    // nonce
    mapping(address => uint256) public nonces;

    mapping(uint256 => EnumerableSet.AddressSet) private authAddress;

    mapping(address => uint256) public authToId;

    // Mapping from address to operator
    mapping(address => bool) public isOperator;

    address public metaverse;
    string public name;
    address public admin;
    uint256 public startId;
    uint256 public totalAccount;

    constructor() {
        _owner = msg.sender;
    }

    function updateMetaverse(address addr) public onlyOwner {
        metaverse = addr;
        name = IMetaverseName(addr).initName();
        startId = IMetaverseName(addr).startId();
    }

    modifier onlyMetaverse() {
        require(metaverse == msg.sender);
        _;
    }

    function setName(string memory _name) public onlyMetaverse {
        name = _name;
    }

    function setAdmin(address _admin) public onlyMetaverse {
        admin = _admin;
    }

    function setOperator(address _operator, bool _isOperator) public onlyMetaverse {
        isOperator[_operator] = _isOperator;
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

    function add(address addr, string calldata name) public onlyMetaverse {
        if (!worlds.contains(addr)) {
            worlds.add(addr);
            worldInfos[addr] = WorldInfo(addr, name, true);
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

    function setAccount(Account calldata account) public onlyMetaverse {
        accounts[account.id] = account;
    }

    function getWorldInfo(address addr) public view returns (WorldInfo memory) {
        return worldInfos[addr];
    }

    function getAccount(uint256 id) public view returns (Account memory) {
        return accounts[id];
    }

    function authAddressContains(uint256 id, address addr) public view returns (bool) {
        return authAddress[id].contains(addr);
    }

    function getAuthAddresses(uint256 id) public view returns (address[] memory) {
        return authAddress[id].values();
    }

    function getAccountAddress(uint256 id) public view returns (address) {
        return authAddress[id].at(0);
    }

    function addAuthAddress(uint256 id, address addr) public onlyMetaverse {
        authAddress[id].add(addr);
        authToId[addr] = id;
    }

    function removeAuthAddress(uint256 id, address addr) public onlyMetaverse {
        authAddress[id].remove(addr);
        delete authToId[addr];
    }

    function removeAllAuthAddress(uint256 id) public onlyMetaverse {
        EnumerableSet.AddressSet storage addrs = authAddress[id];
        for (uint256 i = 0; i < addrs.length(); i++) {
            address addr = addrs.at(i);
            delete authToId[addr];
            addrs.remove(addr);
        }
    }
}
