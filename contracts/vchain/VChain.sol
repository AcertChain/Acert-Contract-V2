//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IVChain.sol";
import "../interfaces/ShellCore.sol";
import "../interfaces/IAcertContract.sol";

contract VChain is ShellContract, IVChain, IAcertContract {
    function createAccountBatch(address[] calldata addrs, bool[] calldata isTrustAdmins) public onlyOwner {
        require(addrs.length == isTrustAdmins.length, "VChain: length is not match");
        require(addrs.length > 0, "VChain: length is zero");

        for (uint256 i = 0; i < addrs.length; i++) {
            core().createAccount_(addrs[i], addrs[i], isTrustAdmins[i]);
        }
    }

    function core() internal view returns (IVChainCore) {
        return IVChainCore(coreContract);
    }

    //emit event
    function emitAddOperator(address operator_) public onlyCore {
        emit AddOperator(operator_);
    }

    function emitRemoveOperator(address operator_) public onlyCore {
        emit RemoveOperator(operator_);
    }

    function emitRegisterWorld(address world_) public onlyCore {
        emit RegisterWorld(world_);
    }

    function emitEnableWorld(address world_) public onlyCore {
        emit EnableWorld(world_);
    }

    function emitDisableWorld(address world_) public onlyCore {
        emit DisableWorld(world_);
    }

    function emitCreateAccount(
        uint256 accountId_,
        address authAddress_,
        bool isTrustAdmin_,
        bool isBWO,
        address sender_,
        uint256 nonce_
    ) public onlyCore {
        emit CreateAccount(accountId_, authAddress_, isTrustAdmin_, isBWO, sender_, nonce_);
    }

    function emitTrustAdmin(
        uint256 accountId_,
        bool isTrustAdmin_,
        bool isBWO,
        address sender_,
        uint256 nonce_
    ) public onlyCore {
        emit TrustAdmin(accountId_, isTrustAdmin_, isBWO, sender_, nonce_);
    }

    function emitFreezeAccount(
        uint256 accountId_,
        bool isBWO_,
        address sender_,
        uint256 nonce_
    ) public onlyCore {
        emit FreezeAccount(accountId_, isBWO_, sender_, nonce_);
    }

    function emitUnFreezeAccount(uint256 accountId_, address newAuthAddress_) public onlyCore {
        emit UnFreezeAccount(accountId_, newAuthAddress_);
    }

    function emitAddAuthAddress(
        uint256 accountId_,
        address authAddress_,
        bool isBWO_,
        address sender_,
        uint256 nonce_
    ) public onlyCore {
        emit AddAuthAddress(accountId_, authAddress_, isBWO_, sender_, nonce_);
    }

    function emitRemoveAuthAddress(
        uint256 accountId_,
        address authAddress_,
        bool isBWO_,
        address sender_,
        uint256 nonce_
    ) public onlyCore {
        emit RemoveAuthAddress(accountId_, authAddress_, isBWO_, sender_, nonce_);
    }

    function emitSetAdmin(address admin) external onlyCore {
        emit SetAdmin(admin);
    }

    /**
     * @dev See {IAcertContract-vchainAddress}.
     */
    function vchainAddress() public view override returns (address) {
        return address(this);
    }

    //IVChain

    /**
     * @dev See {IVChain-name}.
     */
    function name() public view override returns (string memory) {
        return core().name();
    }

    /**
     * @dev See {IVChain-version}.
     */
    function version() public view override returns (string memory) {
        return core().version();
    }

    // account

    /**
     * @dev See {IVChain-createAccount}.
     */
    function createAccount(address _address, bool _isTrustAdmin) public override returns (uint256 id) {
        return core().createAccount_(_msgSender(), _address, _isTrustAdmin);
    }

    /**
     * @dev See {IVChain-createAccountBWO}.
     */
    function createAccountBWO(
        address _address,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override returns (uint256 id) {
        return core().createAccountBWO_(_msgSender(), _address, _isTrustAdmin, sender, deadline, signature);
    }

    /**
     * @dev See {IVChain-addAuthAddress}.
     */
    function addAuthAddress(
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes calldata signature
    ) public override {
        return core().addAuthAddress_(_msgSender(), _id, _address, deadline, signature);
    }

    /**
     * @dev See {IVChain-addAuthAddressBWO}.
     */
    function addAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature,
        bytes memory authSignature
    ) public override {
        return core().addAuthAddressBWO_(_msgSender(), _id, _address, sender, deadline, signature, authSignature);
    }

    /**
     * @dev See {IVChain-removeAuthAddress}.
     */
    function removeAuthAddress(uint256 _id, address _address) public override {
        return core().removeAuthAddress_(_msgSender(), _id, _address);
    }

    /**
     * @dev See {IVChain-removeAuthAddressBWO}.
     */
    function removeAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override {
        return core().removeAuthAddressBWO_(_msgSender(), _id, _address, sender, deadline, signature);
    }

    /**
     * @dev See {IVChain-trustAdmin}.
     */
    function trustAdmin(uint256 _id, bool _isTrustAdmin) public override {
        return core().trustAdmin_(_msgSender(), _id, _isTrustAdmin);
    }

    /**
     * @dev See {IVChain-trustAdminBWO}.
     */
    function trustAdminBWO(
        uint256 _id,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override {
        return core().trustAdminBWO_(_msgSender(), _id, _isTrustAdmin, sender, deadline, signature);
    }

    /**
     * @dev See {IVChain-freezeAccount}.
     */
    function freezeAccount(uint256 _id) public override {
        return core().freezeAccount_(_msgSender(), _id);
    }

    /**
     * @dev See {IVChain-freezeAccountBWO}.
     */
    function freezeAccountBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override {
        return core().freezeAccountBWO_(_msgSender(), _id, sender, deadline, signature);
    }

    /**
     * @dev See {IVChain-getAccountIdByAddress}.
     */
    function getAccountIdByAddress(address _address) public view override returns (uint256 _id) {
        return core().getAccountIdByAddress(_address);
    }

    /**
     * @dev See {IVChain-getAddressByAccountId}.
     */
    function getAddressByAccountId(uint256 _id) public view override returns (address _address) {
        return core().getAddressByAccountId(_id);
    }

    /**
     * @dev See {IVChain-getAccountAuthAddress}.
     */
    function getAccountAuthAddress(uint256 _id) public view override returns (address[] memory) {
        return core().getAccountAuthAddress(_id);
    }

    /**
     * @dev See {IVChain-accountIsExist}.
     */
    function accountIsExist(uint256 _id) public view override returns (bool _isExist) {
        return core().accountIsExist(_id);
    }

    /**
     * @dev See {IVChain-accountIsTrustAdmin}.
     */
    function accountIsTrustAdmin(uint256 _id) public view override returns (bool _isFreeze) {
        return core().accountIsTrustAdmin(_id);
    }

    /**
     * @dev See {IVChain-accountIsFreeze}.
     */
    function accountIsFreeze(uint256 _id) public view override returns (bool _isFreeze) {
        return core().accountIsFreeze(_id);
    }

    /**
     * @dev See {IVChain-checkSender}.
     */
    function checkSender(uint256 _id, address _sender) public view override returns (bool) {
        return core().checkSender(_id, _sender);
    }

    /**
     * @dev See {IVChain-getTotalAccount}.
     */
    function getTotalAccount() public view override returns (uint256) {
        return core().getTotalAccount();
    }

    /**
     * @dev See {IVChain-getNonce}.
     */
    function getNonce(address _address) public view override returns (uint256) {
        return core().getNonce(_address);
    }

    // world
    /**
     * @dev See {IVChain-getWorlds}.
     */
    function getWorlds() public view override returns (address[] memory) {
        return core().getWorlds();
    }
}
