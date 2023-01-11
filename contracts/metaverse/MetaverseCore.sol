//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IWorld.sol";
import "../interfaces/IMetaverse.sol";
import "../interfaces/ShellCore.sol";
import "../interfaces/IAcertContract.sol";
import "./Metaverse.sol";
import "./MetaverseStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract MetaverseCore is IMetaverseCore, CoreContract, IAcertContract, EIP712 {
    string public metverseName;
    string public metverseVersion;
    uint256 public _startId;
    MetaverseStorage public metaStorage;

    modifier onlyAdmin() {
        require(metaStorage.admin() == _msgSender(), "Metaverse: caller is not the admin");
        _;
    }

    constructor(
        string memory name_,
        string memory version_,
        uint256 startId_,
        address metaStorage_
    ) EIP712(name_, version_) {
        metverseName = name_;
        metverseVersion = version_;
        _startId = startId_;
        metaStorage = MetaverseStorage(metaStorage_);
    }

    function shell() public view returns (Metaverse) {
        return Metaverse(shellContract);
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return IAcertContract(shellContract).metaverseAddress();
    }

    //metaverse
    /**
     * @dev See {IMetaverse-name}.
     */
    function name() public view override returns (string memory) {
        return metverseName;
    }

    /**
     * @dev See {IMetaverse-version}.
     */
    function version() public view override returns (string memory) {
        return metverseVersion;
    }

    // account
    /**
     * @dev See {IMetaverseCore-createAccount_}.
     */
    function createAccount_(
        address _msgSender,
        address _address,
        bool _isTrustAdmin
    ) public override onlyShell returns (uint256 id) {
        checkAddressIsNotZero(_address);
        checkAddressIsNotUsed(_address);
        return _createAccount(_address, _isTrustAdmin, false, _msgSender);
    }

    /**
     * @dev See {IMetaverseCore-createAccountBWO_}.
     */
    function createAccountBWO_(
        address _msgSender,
        address _address,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell returns (uint256 id) {
        require(checkBWO(_msgSender), "Metaverse: address is not BWO");
        checkAddressIsNotZero(_address);
        checkAddressIsNotUsed(_address);
        createAccoutBWOParamsVerfiy(_address, _isTrustAdmin, sender, deadline, signature);
        return _createAccount(_address, _isTrustAdmin, true, sender);
    }

    function createAccoutBWOParamsVerfiy(
        address _address,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "createAccountBWO(address _address,bool _isTrustAdmin,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _address,
                        _isTrustAdmin,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        return true;
    }

    function _createAccount(
        address _address,
        bool _isTrustAdmin,
        bool _isBWO,
        address _sender
    ) private returns (uint256 id) {
        if (_isTrustAdmin) {
            require(_address == _sender, "Metaverse: Only AuthAddress can set trustAdmin to true");
        }
        metaStorage.IncrementTotalAccount();
        id = metaStorage.totalAccount() + _startId;
        metaStorage.setAccount(MetaverseStorage.Account(true, _isTrustAdmin, false, id));
        metaStorage.addAuthAddress(id, _address);
        shell().emitCreateAccount(id, _address, _isTrustAdmin, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    /**
     * @dev See {IMetaverseCore-addAuthAddress_}.
     */
    function addAuthAddress_(
        address _msgSender,
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell {
        checkAddressIsNotZero(_address);
        checkAddressIsNotUsed(_address);
        checkSender(_id, _msgSender);
        checkAuthAddressSignature(_id, _address, _msgSender, deadline, signature);
        _addAuthAddress(_id, _address, false, _msgSender);
    }

    /**
     * @dev See {IMetaverseCore-addAuthAddressBWO_}.
     */
    function addAuthAddressBWO_(
        address _msgSender,
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature,
        bytes memory authSignature
    ) public override onlyShell {
        require(checkBWO(_msgSender), "Metaverse: address is not BWO");

        addAuthAddressBWOParamsVerfiy(_id, _address, sender, deadline, signature);
        checkAuthAddressSignature(_id, _address, sender, deadline, authSignature);
        _addAuthAddress(_id, _address, true, sender);
    }

    function addAuthAddressBWOParamsVerfiy(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        checkSender(_id, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "addAuthAddressBWO(uint256 id,address addr,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _id,
                        _address,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        return true;
    }

    function checkAuthAddressSignature(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        uint256 nonce = getNonce(_address);
        _recoverSig(
            deadline,
            _address,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("AddAuth(uint256 id,address addr,address sender,uint256 nonce,uint256 deadline)"),
                        _id,
                        _address,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        return true;
    }

    function _addAuthAddress(
        uint256 _id,
        address _address,
        bool _isBWO,
        address _sender
    ) private {
        checkAddressIsNotUsed(_address);
        metaStorage.addAuthAddress(_id, _address);

        shell().emitAddAuthAddress(_id, _address, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_address);
        metaStorage.IncrementNonce(_sender);
    }

    /**
     * @dev See {IMetaverseCore-removeAuthAddress_}.
     */
    function removeAuthAddress_(
        address _msgSender,
        uint256 _id,
        address _address
    ) public override onlyShell {
        checkAddressIsNotZero(_address);
        checkSender(_id, _msgSender);
        _removeAuthAddress(_id, _address, false, _msgSender);
    }

    /**
     * @dev See {IMetaverseCore-removeAuthAddressBWO_}.
     */
    function removeAuthAddressBWO_(
        address _msgSender,
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell {
        require(checkBWO(_msgSender), "Metaverse: address is not BWO");
        checkAddressIsNotZero(_address);
        removeAuthAddressBWOParamsVerfiy(_id, _address, sender, deadline, signature);
        _removeAuthAddress(_id, _address, true, sender);
    }

    function removeAuthAddressBWOParamsVerfiy(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        checkSender(_id, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "removeAuthAddressBWO(uint256 id,address addr,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _id,
                        _address,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        return true;
    }

    function _removeAuthAddress(
        uint256 _id,
        address _address,
        bool _isBWO,
        address _sender
    ) private {
        require(_address != _sender, "Metaverse: AuthAddress can not remove itself");
        metaStorage.removeAuthAddress(_id, _address);
        shell().emitRemoveAuthAddress(_id, _address, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    /**
     * @dev See {IMetaverseCore-trustAdmin_}.
     */
    function trustAdmin_(
        address _msgSender,
        uint256 _id,
        bool _isTrustAdmin
    ) public override onlyShell {
        checkSender(_id, _msgSender);
        _trustAdmin(_id, _isTrustAdmin, false, _msgSender);
    }

    /**
     * @dev See {IMetaverseCore-trustAdminBWO_}.
     */
    function trustAdminBWO_(
        address _msgSender,
        uint256 _id,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell {
        require(checkBWO(_msgSender), "Metaverse: address is not BWO");
        trustAdminBWOParamsVerify(_id, _isTrustAdmin, sender, deadline, signature);
        _trustAdmin(_id, _isTrustAdmin, true, sender);
    }

    function trustAdminBWOParamsVerify(
        uint256 _id,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        checkSender(_id, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "trustAdminBWO(uint256 id,bool isTrustAdmin,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _id,
                        _isTrustAdmin,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        return true;
    }

    function _trustAdmin(
        uint256 _id,
        bool _isTrustAdmin,
        bool _isBWO,
        address _sender
    ) private {
        MetaverseStorage.Account memory account = metaStorage.getAccount(_id);
        require(account.isExist == true, "Metaverse: account is not exist");
        account.isTrustAdmin = _isTrustAdmin;
        metaStorage.setAccount(account);
        shell().emitTrustAdmin(_id, _isTrustAdmin, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    /**
     * @dev See {IMetaverseCore-freezeAccount_}.
     */
    function freezeAccount_(address _msgSender, uint256 _id) public override onlyShell {
        MetaverseStorage.Account memory account = metaStorage.getAccount(_id);
        if (_msgSender == metaStorage.admin() && getAccountIdByAddress(_msgSender) != _id) {
            require((account.isTrustAdmin), "Metaverse: admin does not have permission to freeze the account");
        } else {
            checkSender(_id, _msgSender);
        }
        _freezeAccount(_id, false, _msgSender);
    }

    /**
     * @dev See {IMetaverseCore-freezeAccountBWO_}.
     */
    function freezeAccountBWO_(
        address _msgSender,
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell {
        require(checkBWO(_msgSender), "Metaverse: address is not BWO");

        freezeAccountBWOParamsVerify(_id, sender, deadline, signature);
        _freezeAccount(_id, true, sender);
    }

    function freezeAccountBWOParamsVerify(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        checkSender(_id, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("freezeAccountBWO(uint256 id,address sender,uint256 nonce,uint256 deadline)"),
                        _id,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        return true;
    }

    function _freezeAccount(
        uint256 _id,
        bool _isBWO,
        address _sender
    ) private {
        MetaverseStorage.Account memory account = metaStorage.getAccount(_id);
        require(account.isFreeze == false, "Metaverse: The account has been frozen");
        account.isFreeze = true;
        account.isTrustAdmin = true;
        metaStorage.setAccount(account);
        shell().emitFreezeAccount(_id, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    /**
     * @dev Only Admin can unfreeze account.
     */
    function unfreezeAccount(uint256 _id, address newAddress) public onlyAdmin {
        checkAddressIsNotZero(newAddress);
        checkAddressIsNotUsed(newAddress);
        MetaverseStorage.Account memory account = metaStorage.getAccount(_id);
        require(account.isFreeze, "Metaverse: The accounts were not frozen");
        account.isFreeze = false;
        metaStorage.setAccount(account);

        metaStorage.removeAllAuthAddress(_id);
        metaStorage.addAuthAddress(_id, newAddress);
        shell().emitUnFreezeAccount(_id, newAddress);
    }

    /**
     * @dev See {IMetaverse-getAccountIdByAddress}.
     */
    function getAccountIdByAddress(address _address) public view override returns (uint256 _id) {
        return metaStorage.authToId(_address);
    }

    /**
     * @dev See {IMetaverse-getAddressByAccountId}.
     */
    function getAddressByAccountId(uint256 _id) public view override returns (address _address) {
        return metaStorage.getAccountAddress(_id);
    }

    /**
     * @dev See {IMetaverse-getAccountAuthAddress}.
     */
    function getAccountAuthAddress(uint256 _id) public view override returns (address[] memory) {
        return metaStorage.getAuthAddresses(_id);
    }

    /**
     * @dev See {IMetaverse-accountIsExist}.
     */
    function accountIsExist(uint256 _id) public view override returns (bool _isExist) {
        return metaStorage.getAccount(_id).isExist;
    }

    /**
     * @dev See {IMetaverse-accountIsTrustAdmin}.
     */
    function accountIsTrustAdmin(uint256 _id) public view override returns (bool _isFreeze) {
        return metaStorage.getAccount(_id).isTrustAdmin;
    }

    /**
     * @dev See {IMetaverse-accountIsFreeze}.
     */
    function accountIsFreeze(uint256 _id) public view override returns (bool _isFreeze) {
        return metaStorage.getAccount(_id).isFreeze;
    }

    /**
     * @dev See {IMetaverse-checkSender}.
     */
    function checkSender(uint256 _id, address _sender) public view override returns (bool) {
        require(accountIsExist(_id), "Metaverse: Account does not exist");
        require(metaStorage.authAddressContains(_id, _sender), "Metaverse: Sender is not authorized");
        return true;
    }

    /**
     * @dev See {IMetaverse-getTotalAccount}.
     */
    function getTotalAccount() public view override returns (uint256) {
        return metaStorage.totalAccount();
    }

    // world
    /**
     * @dev See {IMetaverse-getWorlds}.
     */
    function getWorlds() public view override returns (address[] memory) {
        return metaStorage.getWorlds();
    }

    /**
     * @dev See {IMetaverse-getNonce}.
     */
    function getNonce(address _address) public view override returns (uint256) {
        return metaStorage.nonces(_address);
    }

    // Owner functions
    function registerWorld(address _world) public onlyOwner {
        checkAddressIsNotZero(_world);
        require(metaStorage.worldContains(_world) == false, "Metaverse: world is exist");
        require(
            IAcertContract(_world).metaverseAddress() == IAcertContract(shellContract).metaverseAddress(),
            "Metaverse: metaverse is not match"
        );
        metaStorage.addWorld(_world);
        shell().emitRegisterWorld(_world);
    }

    function enableWorld(address _world) public onlyOwner {
        metaStorage.enableWorld(_world);
        shell().emitEnableWorld(_world);
    }

    function disableWorld(address _world) public onlyOwner {
        metaStorage.disableWorld(_world);
        shell().emitDisableWorld(_world);
    }

    function setAdmin(address _address) public onlyOwner {
        checkAddressIsNotZero(_address);
        metaStorage.setAdmin(_address);
        shell().emitSetAdmin(_address);
    }

    function getAdmin() public view returns (address) {
        return metaStorage.admin();
    }

    function addOperator(address _operator) public onlyOwner {
        checkAddressIsNotZero(_operator);
        metaStorage.setOperator(_operator, true);
        shell().emitAddOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner {
        metaStorage.setOperator(_operator, false);
        shell().emitRemoveOperator(_operator);
    }

    // utils
    function checkBWO(address _address) public view returns (bool) {
        return (metaStorage.isOperator(_address) || owner() == _address);
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(deadline == 0 || block.timestamp < deadline, "Metaverse: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "Metaverse: recoverSig failed");
    }

    function checkAddressIsNotUsed(address _address) internal view {
        require(getAccountIdByAddress(_address) == 0, "Metaverse: new address has been used");
    }

    function checkAddressIsNotZero(address _address) internal pure {
        require(_address != address(0), "Metaverse: address is zero");
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }
}
