//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IWorld.sol";
import "../interfaces/IAcertContract.sol";
import "../interfaces/IVChain.sol";

contract World is IWorld, ShellContract, IAcertContract {
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

    /**
     * @dev See {IAcertContract-vchainAddress}.
     */
    function vchainAddress() public view override returns (address) {
        return IAcertContract(coreContract).vchainAddress();
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
}
