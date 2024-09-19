//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IAcertContract.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorldStorage is IAcertContract, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private assets;
    EnumerableSet.AddressSet private safeContracts;

    // Mapping from address to safe contract
    mapping(address => bool) public isSafeContract;
    // Mapping from address to Asset
    mapping(address => bool) public isEnabledAsset;
    // nonce
    mapping(address => uint256) public nonces;

    mapping(address => bool) public isOperator;

    address public world;

    modifier onlyWorld() {
        require(world == msg.sender);
        _;
    }

    /**
     * @dev See {IAcertContract-vchainAddress}.
     */
    function vchainAddress() public view override returns (address) {
        return IAcertContract(world).vchainAddress();
    }

    function updateWorld(address _address) public onlyOwner {
        require(_address != address(0), "Wrold: address is zero");
        world = _address;
    }

    function setOperator(address _operator, bool _isOperator) public onlyWorld {
        isOperator[_operator] = _isOperator;
    }

    function IncrementNonce(address _sender) public onlyWorld {
        nonces[_sender]++;
    }

    function assetContains(address _address) public view returns (bool) {
        return assets.contains(_address);
    }

    function addAsset(address _address) public onlyWorld {
        require(!assets.contains(_address), "World: asset is already exist");
        assets.add(_address);
        isEnabledAsset[_address] = true;
    }

    function getAssets() public view returns (address[] memory) {
        return assets.values();
    }

    function assetCount() public view returns (uint256) {
        return assets.length();
    }

    function enableAsset(address _address) public onlyWorld {
        require(assets.contains(_address), "World: asset is not exist");
        isEnabledAsset[_address] = true;
    }

    function disableAsset(address _address) public onlyWorld {
        require(assets.contains(_address), "World: asset is not exist");
        isEnabledAsset[_address] = false;
    }

    function addSafeContract(address _address) public onlyWorld {
        require(!safeContracts.contains(_address), "World: safeContract is already exist");
        safeContracts.add(_address);
        isSafeContract[_address] = true;
    }

    function removeSafeContract(address _address) public onlyWorld {
        require(safeContracts.contains(_address), "World: safeContract is not exist");
        safeContracts.remove(_address);
        isSafeContract[_address] = false;
    }

    function getSafeContracts() public view returns (address[] memory) {
        return safeContracts.values();
    }
}
