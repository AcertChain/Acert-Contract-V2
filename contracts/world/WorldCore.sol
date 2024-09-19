//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IAsset.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IVChain.sol";
import "../interfaces/IAcertContract.sol";
import "./World.sol";
import "./WorldStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract WorldCore is IWorldCore, CoreContract, IAcertContract, EIP712 {
    //world
    /**
     * @dev See {IWorld-name}.
     */
    string public override name;
    /**
     * @dev See {IWorld-version}.
     */
    string public override version;
    WorldStorage worldStorage;
    IVChain vchain;

    constructor(
        string memory _name,
        string memory _version,
        address _vchain,
        address _worldStorage
    ) EIP712(_name, _version) {
        vchain = IVChain(_vchain);
        name = _name;
        version = _version;
        worldStorage = WorldStorage(_worldStorage);
    }

    function shell() public view returns (World) {
        return World(shellContract);
    }

    /**
     * @dev See {IAcertContract-vchainAddress}.
     */
    function vchainAddress() public view override returns (address) {
        return address(vchain);
    }

    //asset
    /**
     * @dev See {IWorld-getAssets}.
     */
    function getAssets() public view override returns (address[] memory) {
        return worldStorage.getAssets();
    }

    /**
     * @dev See {IWorld-isEnabledAsset}.
     */
    function isEnabledAsset(address _address) public view override returns (bool) {
        return worldStorage.isEnabledAsset(_address);
    }

    //safeContract
    /**
     * @dev See {IWorld-getSafeContracts}.
     */
    function getSafeContracts() public view override returns (address[] memory) {
        return worldStorage.getSafeContracts();
    }

    /**
     * @dev See {IWorld-isSafeContract}.
     */
    function isSafeContract(address _address) public view override returns (bool) {
        return worldStorage.isSafeContract(_address);
    }

    function addOperator(address _operator) public onlyOwner {
        checkAddressIsNotZero(_operator);
        worldStorage.setOperator(_operator, true);
        shell().emitAddOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner {
        worldStorage.setOperator(_operator, false);
        shell().emitRemoveOperator(_operator);
    }

    /**
     * @dev See {IWorld-checkBWO}.
     */
    function checkBWO(address _address) public view override returns (bool) {
        return (worldStorage.isOperator(_address) || owner() == _address);
    }

    function getNonce(address _address) public view override returns (uint256) {
        return worldStorage.nonces(_address);
    }

    // Owner functions
    function registerAsset(address _address) public onlyOwner {
        checkAddressIsNotZero(_address);
        require(worldStorage.assetContains(_address) == false, "World: asset is exist");
        require(IAsset(_address).worldAddress() == address(shellContract), "World: world address is not match");
        worldStorage.addAsset(_address);
        shell().emitRegisterAsset(_address);
    }

    function disableAsset(address _address) public onlyOwner {
        worldStorage.disableAsset(_address);
        shell().emitDisableAsset(_address);
    }

    function enableAsset(address _address) public onlyOwner {
        worldStorage.enableAsset(_address);
        shell().emitEnableAsset(_address);
    }

    function addSafeContract(address _address) public onlyOwner {
        checkAddressIsNotZero(_address);
        worldStorage.addSafeContract(_address);
        shell().emitAddSafeContract(_address);
    }

    function removeSafeContract(address _address) public onlyOwner {
        worldStorage.removeSafeContract(_address);
        shell().emitRemoveSafeContract(_address);
    }

    // utils
    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes calldata signature
    ) internal view {
        require(deadline == 0 || block.timestamp < deadline, "World: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "World: recoverSig failed");
    }

    function checkAddressIsNotZero(address _address) internal pure {
        require(_address != address(0), "World: address is zero");
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }
}
