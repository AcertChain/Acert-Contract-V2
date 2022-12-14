//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IWorld.sol";
import "../interfaces/IAcertContract.sol";

contract World is IWorld, WorldShell, IAcertContract {
    function core() internal view returns (IWorldCore) {
        return IWorldCore(coreContract);
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return IAcertContract(coreContract).metaverseAddress();
    }

    //IWorld


    function getNonce(address account) public view override returns (uint256) {
        return core().getNonce(account);
    }


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
        bytes memory signature
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
        bytes memory signature
    ) public override {
        return core().trustWorldBWO_(_msgSender(), _id, _isTrustWorld, sender, deadline, signature);
    }
}
