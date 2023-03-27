//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IWorld.sol";
import "../interfaces/IAcertContract.sol";
import "../interfaces/IMetaverse.sol";

contract World is IWorld, ShellContract, IAcertContract {
    function trustWorldBatch(uint256[] calldata ids, bool[] calldata isTrusts) public onlyOwner {
        IMetaverse meta = IMetaverse(metaverseAddress());
        for (uint256 i = 0; i < ids.length; i++) {
            address sender = meta.getAddressByAccountId(ids[i]);
            core().trustWorld_(sender, ids[i], isTrusts[i]);
        }
    }

    function core() internal view returns (IWorldCore) {
        return IWorldCore(coreContract);
    }

    //emit event
    function emitAddOperator(address operator_) public onlyCore {
        emit AddOperator(operator_);
    }

    function emitRemoveOperator(address operator_) public onlyCore {
        emit AddOperator(operator_);
    }

    function emitRegisterAsset(address _asset) public onlyCore {
        emit RegisterAsset(_asset);
    }

    function emitEnableAsset(address _asset) public onlyCore {
        emit EnableAsset(_asset);
    }

    function emitDisableAsset(address _asset) public onlyCore {
        emit DisableAsset(_asset);
    }

    function emitAddSafeContract(address _contract) public onlyCore {
        emit AddSafeContract(_contract);
    }

    function emitRemoveSafeContract(address _contract) public onlyCore {
        emit RemoveSafeContract(_contract);
    }

    function emitTrustWorld(
        uint256 _accountId,
        bool _isTrustWorld,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit TrustWorld(_accountId, _isTrustWorld, isBWO, sender, nonce);
    }

    function emitTrustContract(
        uint256 _accountId,
        address _safeContract,
        bool _isTrustContract,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit TrustContract(_accountId, _safeContract, _isTrustContract, isBWO, sender, nonce);
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return IAcertContract(coreContract).metaverseAddress();
    }

    //IWorld

    /**
     * @dev See {IWorld-name}.
     */
    function name() public view override returns (string memory) {
        return core().name();
    }

    /**
     * @dev See {IWorld-version}.
     */
    function version() public view override returns (string memory) {
        return core().version();
    }

    // account
    function isTrustWorld(uint256 _id) public view override returns (bool _isTrustWorld) {
        return core().isTrustWorld(_id);
    }

    function isTrustContract(address _contract, uint256 _id) public view override returns (bool _isTrustContract) {
        return core().isTrustContract(_contract, _id);
    }

    function isTrust(address _contract, uint256 _id) public view override returns (bool _isTrust) {
        return core().isTrust(_contract, _id);
    }

    function getNonce(address _address) public view override returns (uint256) {
        return core().getNonce(_address);
    }

    // asset
    function getAssets() public view override returns (address[] memory) {
        return core().getAssets();
    }

    function isEnabledAsset(address _address) public view override returns (bool) {
        return core().isEnabledAsset(_address);
    }

    // safeContract
    function getSafeContracts() public view override returns (address[] memory) {
        return core().getSafeContracts();
    }

    function isSafeContract(address _address) public view override returns (bool) {
        return core().isSafeContract(_address);
    }

    function checkBWO(address _address) public view override returns (bool) {
        return core().checkBWO(_address);
    }

    function trustContract(
        uint256 _id,
        address _contract,
        bool _isTrustContract
    ) public override {
        return core().trustContract_(_msgSender(), _id, _contract, _isTrustContract);
    }

    function trustContractBWO(
        uint256 _id,
        address _contract,
        bool _isTrustContract,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override {
        return core().trustContractBWO_(_msgSender(), _id, _contract, _isTrustContract, sender, deadline, signature);
    }

    function trustWorld(uint256 _id, bool _isTrustWorld) public override {
        return core().trustWorld_(_msgSender(), _id, _isTrustWorld);
    }

    function trustWorldBWO(
        uint256 _id,
        bool _isTrustWorld,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override {
        return core().trustWorldBWO_(_msgSender(), _id, _isTrustWorld, sender, deadline, signature);
    }
}
