//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IAsset.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IAcertContract.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorldStorage is IAcertContract, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private assets;

    // Mapping from address to trust contract
    mapping(address => bool) public isSafeContract;
    // Mapping from account Id to contract
    mapping(uint256 => mapping(address => bool)) public isTrustContractByAccountId;
    // Mapping from address to Asset
    mapping(address => bool) public isEnabledAsset;
    // Mapping from is trust world
    mapping(uint256 => bool) public isTrustWorld;
    // nonce
    mapping(address => uint256) public nonces;

    mapping(address => bool) public isOperator;

    address public world;

    constructor() {}

    modifier onlyWorld() {
        require(world == msg.sender);
        _;
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return IAcertContract(world).metaverseAddress();
    }

    function updateWorld(address _address) public onlyOwner {
        require(_address != address(0));
        world = _address;
    }

    function setOperator(address _operator, bool _isOperator) public onlyWorld {
        isOperator[_operator] = _isOperator;
    }

    function IncrementNonce(address _sender) public onlyWorld {
        nonces[_sender]++;
    }

    function assetContains(address addr) public view returns (bool) {
        return assets.contains(addr);
    }

    function addAsset(address addr) public onlyWorld {
        if (!assets.contains(addr)) {
            assets.add(addr);
            isEnabledAsset[addr] = true;
        }
    }

    function getAssets() public view returns (address[] memory) {
        return assets.values();
    }

    function assetCount() public view returns (uint256) {
        return assets.length();
    }

    function enableAsset(address addr) public onlyWorld {
        require(assets.contains(addr), "World: asset is not exist");
        isEnabledAsset[addr] = true;
    }

    function disableAsset(address addr) public onlyWorld {
        require(assets.contains(addr), "World: asset is not exist");
        isEnabledAsset[addr] = false;
    }

    function addSafeContract(address _address) public onlyWorld {
        isSafeContract[_address] = true;
    }

    function removeSafeContract(address _address) public onlyWorld {
        require(isSafeContract[_address], "World: safeContract is not exist");
        isSafeContract[_address] = false;
    }

    function setTrustContractByAccountId (
        uint256 _accountId,
        address _address,
        bool _isTrust
    ) public onlyWorld {
        isTrustContractByAccountId[_accountId][_address] = _isTrust;
    }

    function setTrustWorld(uint256 _accountId, bool _isTrust) public onlyWorld {
        isTrustWorld[_accountId] = _isTrust;
    }
}
