//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IMetaverse.sol";
import "../interfaces/IAcertContract.sol";

contract Metaverse is IMetaverse, MetaverseShell, IAcertContract {
    function core() internal view returns (IMetaverseCore) {
        return IMetaverseCore(coreContract);
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return address(this);
    }

    //IMetaverse

    /**
     * @dev See {IMetaverse-name}.
     */
    function name() public view override returns (string memory) {
        return core().name();
    }

    /**
     * @dev See {IMetaverse-version}.
     */
    function version() public view override returns (string memory) {
        return core().version();
    }

    // account

    /**
     * @dev See {IMetaverse-createAccount}.
     */
    function createAccount(address _address, bool _isTrustAdmin) public override returns (uint256 id) {
        return core().createAccount_(_msgSender(), _address, _isTrustAdmin);
    }

    /**
     * @dev See {IMetaverse-createAccountBWO}.
     */
    function createAccountBWO(
        address _address,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override returns (uint256 id) {
        return core().createAccountBWO_(_msgSender(), _address, _isTrustAdmin, sender, deadline, signature);
    }

    /**
     * @dev See {IMetaverse-addAuthAddress}.
     */
    function addAuthAddress(
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes memory signature
    ) public override {
        return core().addAuthAddress_(_msgSender(), _id, _address, deadline, signature);
    }

    /**
     * @dev See {IMetaverse-addAuthAddressBWO}.
     */
    function addAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature,
        bytes memory authSignature
    ) public override {
        return core().addAuthAddressBWO_(_msgSender(), _id, _address, sender, deadline, signature, authSignature);
    }

    /**
     * @dev See {IMetaverse-removeAuthAddress}.
     */
    function removeAuthAddress(uint256 _id, address _address) public override {
        return core().removeAuthAddress_(_msgSender(), _id, _address);
    }

    /**
     * @dev See {IMetaverse-removeAuthAddressBWO}.
     */
    function removeAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override {
        return core().removeAuthAddressBWO_(_msgSender(), _id, _address, sender, deadline, signature);
    }

    /**
     * @dev See {IMetaverse-trustAdmin}.
     */
    function trustAdmin(uint256 _id, bool _isTrustAdmin) public override {
        return core().trustAdmin_(_msgSender(), _id, _isTrustAdmin);
    }

    /**
     * @dev See {IMetaverse-trustAdminBWO}.
     */
    function trustAdminBWO(
        uint256 _id,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override {
        return core().trustAdminBWO_(_msgSender(), _id, _isTrustAdmin, sender, deadline, signature);
    }

    /**
     * @dev See {IMetaverse-freezeAccount}.
     */
    function freezeAccount(uint256 _id) public override {
        return core().freezeAccount_(_msgSender(), _id);
    }

    /**
     * @dev See {IMetaverse-freezeAccountBWO}.
     */
    function freezeAccountBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override {
        return core().freezeAccountBWO_(_msgSender(), _id, sender, deadline, signature);
    }

    /**
     * @dev See {IMetaverse-getAccountIdByAddress}.
     */
    function getAccountIdByAddress(address _address) public view override returns (uint256 _id) {
        return core().getAccountIdByAddress(_address);
    }

    /**
     * @dev See {IMetaverse-getAddressByAccountId}.
     */
    function getAddressByAccountId(uint256 _id) public view override returns (address _address) {
        return core().getAddressByAccountId(_id);
    }

    /**
     * @dev See {IMetaverse-getAccountAuthAddress}.
     */
    function getAccountAuthAddress(uint256 _id) public view override returns (address[] memory) {
        return core().getAccountAuthAddress(_id);
    }

    /**
     * @dev See {IMetaverse-accountIsExist}.
     */
    function accountIsExist(uint256 _id) public view override returns (bool _isExist) {
        return core().accountIsExist(_id);
    }

    /**
     * @dev See {IMetaverse-accountIsTrustAdmin}.
     */
    function accountIsTrustAdmin(uint256 _id) public view override returns (bool _isFreeze) {
        return core().accountIsTrustAdmin(_id);
    }

    /**
     * @dev See {IMetaverse-accountIsFreeze}.
     */
    function accountIsFreeze(uint256 _id) public view override returns (bool _isFreeze) {
        return core().accountIsFreeze(_id);
    }

    /**
     * @dev See {IMetaverse-checkSender}.
     */
    function checkSender(uint256 _id, address _sender) public view override returns (bool) {
        return core().checkSender(_id, _sender);
    }

    /**
     * @dev See {IMetaverse-getTotalAccount}.
     */
    function getTotalAccount() public view override returns (uint256) {
        return core().getTotalAccount();
    }

    // world
    /**
     * @dev See {IMetaverse-getWorlds}.
     */
    function getWorlds() public view override returns (address[] memory) {
        return core().getWorlds();
    }

    // world
    /**
     * @dev See {IMetaverse-getNonce}.
     */
    function getNonce(address account) public view override returns (uint256) {
        return core().getNonce(account);
    }
}
