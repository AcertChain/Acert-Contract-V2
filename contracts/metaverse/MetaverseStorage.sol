//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAcertContract.sol";

contract MetaverseStorage is IAcertContract, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private worlds;

    struct Account {
        bool isExist;
        bool isTrustAdmin;
        bool isFreeze;
        uint256 id;
    }

    // Mapping from address to Asset
    mapping(address => bool) public isEnabledWorld;
    // Mapping from account ID to Account
    mapping(uint256 => Account) public accounts;
    // nonce
    mapping(address => uint256) public nonces;

    mapping(uint256 => EnumerableSet.AddressSet) private authAddress;

    mapping(address => uint256) public authToId;

    // Mapping from address to operator
    mapping(address => bool) public isOperator;

    address public metaverse;
    address public admin;
    uint256 public totalAccount;

    modifier onlyMetaverse() {
        require(metaverse == msg.sender, "MetaverseStorage: caller is not the metaverse");
        _;
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return address(IAcertContract(metaverse).metaverseAddress());
    }

    function updateMetaverse(address _address) public onlyOwner {
        require(_address != address(0), "MetaverseStorage: address is zero");
        metaverse = _address;
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

    function IncrementNonce(address _sender) public onlyMetaverse {
        nonces[_sender]++;
    }

    function worldContains(address _address) public view returns (bool) {
        return worlds.contains(_address);
    }

    function addWorld(address _address) public onlyMetaverse {
        if (!worlds.contains(_address)) {
            worlds.add(_address);
            isEnabledWorld[_address] = true;
        }
    }

    function getWorlds() public view returns (address[] memory) {
        return worlds.values();
    }

    function worldCount() public view returns (uint256) {
        return worlds.length();
    }

    function enableWorld(address _address) public onlyMetaverse {
        require(worlds.contains(_address), "Metaverse: world is not exist");
        isEnabledWorld[_address] = true;
    }

    function disableWorld(address _address) public onlyMetaverse {
        require(worlds.contains(_address), "Metaverse: world is not exist");
        isEnabledWorld[_address] = false;
    }

    function setAccount(Account calldata account) public onlyMetaverse {
        accounts[account.id] = account;
    }

    function getAccount(uint256 id) public view returns (Account memory) {
        return accounts[id];
    }

    function authAddressContains(uint256 id, address _address) public view returns (bool) {
        return authAddress[id].contains(_address);
    }

    function getAuthAddresses(uint256 id) public view returns (address[] memory) {
        return authAddress[id].values();
    }

    function getAccountAddress(uint256 id) public view returns (address) {
        return (authAddress[id].length() != 0) ? authAddress[id].at(0) : address(0);
    }

    function addAuthAddress(uint256 id, address _address) public onlyMetaverse {
        authAddress[id].add(_address);
        authToId[_address] = id;
    }

    function removeAuthAddress(uint256 id, address _address) public onlyMetaverse {
        authAddress[id].remove(_address);
        delete authToId[_address];
    }

    function removeAllAuthAddress(uint256 id) public onlyMetaverse {
        EnumerableSet.AddressSet storage addrs = authAddress[id];
        for (uint256 i = 0; i < addrs.length(); i++) {
            address _address = addrs.at(i);
            delete authToId[_address];
            addrs.remove(_address);
        }
    }
}
