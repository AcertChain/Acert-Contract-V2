//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../common/Ownable.sol";
import "../interfaces/IApplyStorage.sol";
import "../interfaces/IMetaverse.sol";
import "../interfaces/IWorld.sol";
import "../storage/MetaverseStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract MogaMetaverse is IMetaverse, IApplyStorage, Context, Ownable, EIP712 {
    MetaverseStorage public metaStorage;

    string public override name;
    uint256 public startId;

    constructor(
        string memory name_,
        string memory version_,
        uint256 startId_,
        address metaStorage_
    ) EIP712(name_, version_) {
        name = name_;
        emit SetName(name_);
        _owner = _msgSender();
        startId = startId_;
        metaStorage = MetaverseStorage(metaStorage_);
    }

    /**
     * @dev See {IApplyStorage-getStorageAddress}.
     */
    function getStorageAddress() external view override returns (address) {
        return address(metaStorage);
    }

    function registerWorld(address _world) public onlyOwner {
        checkAddressIsNotZero(_world);
        require(containsWorld(_world) == false, "Metaverse: world is exist");
        require(IWorld(_world).getMetaverse() == address(this), "Metaverse: metaverse is not match");
        string memory _name = IWorld(_world).name();
        metaStorage.add(_world, _name);
        emit RegisterWorld(_world, _name);
    }

    function disableWorld(address _world) public onlyOwner {
        checkAddressIsNotZero(_world);
        metaStorage.disableWorld(_world);
        emit DisableWorld(_world);
    }

    function getWorldInfo(address _world) public view returns (MetaverseStorage.WorldInfo memory) {
        return metaStorage.getWorldInfo(_world);
    }

    function containsWorld(address _world) public view returns (bool) {
        return metaStorage.contains(_world);
    }

    function getWorlds() public view returns (address[] memory) {
        return metaStorage.values();
    }

    function getWorldCount() public view returns (uint256) {
        return metaStorage.length();
    }

    function setAdmin(address _address) public onlyOwner {
        checkAddressIsNotZero(_address);
        metaStorage.setAdmin(_address);
        emit SetAdmin(_address);
    }

    function addOperator(address _operator) public onlyOwner {
        checkAddressIsNotZero(_operator);
        metaStorage.setOperator(_operator, true);
        emit AddOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner {
        metaStorage.setOperator(_operator, false);
        emit RemoveOperator(_operator);
    }

    function createAccount(address _address, bool _isTrustAdmin) public returns (uint256 id) {
        checkAddressIsNotZero(_address);
        checkAddressIsNotUsed(_address);
        metaStorage.IncrementTotalAccount();
        id = metaStorage.totalAccount() + startId;
        metaStorage.setAccount(MetaverseStorage.Account(true, _isTrustAdmin, false, id));
        metaStorage.addAuthAddress(id, _address);
        emit CreateAccount(id, _address, _isTrustAdmin);
    }

    function trustAdmin(uint256 _id, bool _isTrustAdmin) public {
        checkSender(_id, _msgSender());
        _trustAdmin(_id, _isTrustAdmin, false, _msgSender());
    }

    function trustAdminBWO(
        uint256 _id,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(checkBWO(_msgSender()), "Metaverse: address is not BWO");
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
                        keccak256("BWO(uint256 id,bool isTrustAdmin,address sender,uint256 nonce,uint256 deadline)"),
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
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isExist == true, "Metaverse: account is not exist");
        account.isTrustAdmin = _isTrustAdmin;
        metaStorage.setAccount(account);
        emit TrustAdmin(_id, _isTrustAdmin, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    function freezeAccount(uint256 _id) public {
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        if (_msgSender() == metaStorage.admin() && getAccountIdByAddress(_msgSender()) != _id) {
            require((account.isTrustAdmin), "Metaverse: admin does not have permission to freeze the account");
        } else {
            checkSender(_id, _msgSender());
        }
        _freezeAccount(_id, false, _msgSender());
    }

    function freezeAccountBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(checkBWO(_msgSender()), "Metaverse: address is not BWO");

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
                        keccak256("BWO(uint256 id,address sender,uint256 nonce,uint256 deadline)"),
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
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isFreeze == false, "Metaverse: The account has been frozen");
        account.isFreeze = true;
        account.isTrustAdmin = true;
        metaStorage.setAccount(account);
        emit FreezeAccount(_id, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    function unfreezeAccount(uint256 _id, address newAddress) public {
        checkAddressIsNotZero(newAddress);
        checkAddressIsNotUsed(newAddress);
        require(_msgSender() == metaStorage.admin(), "Metaverse: sender is not admin");
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isFreeze, "Metaverse: The accounts were not frozen");
        account.isFreeze = false;
        metaStorage.setAccount(account);

        metaStorage.removeAllAuthAddress(_id);
        metaStorage.addAuthAddress(_id, newAddress);
        emit UnFreezeAccount(_id, newAddress);
    }

    function addAuthAddress(
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes memory signature
    ) public {
        checkAddressIsNotZero(_address);
        checkAddressIsNotUsed(_address);
        checkSender(_id, _msgSender());
        checkAuthAddressSignature(_id, _address, _msgSender(), deadline, signature);
        _addAuthAddress(_id, _address, false, _msgSender());
    }

    function addAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature,
        bytes memory authSignature
    ) public {
        require(checkBWO(_msgSender()), "Metaverse: address is not BWO");

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
                        keccak256("BWO(uint256 id,address addr,address sender,uint256 nonce,uint256 deadline)"),
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

        emit AuthAddressChanged(_id, _address, OperationEnum.ADD, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_address);
        metaStorage.IncrementNonce(_sender);
    }

    function removeAuthAddress(uint256 _id, address _address) public {
        checkAddressIsNotZero(_address);
        checkSender(_id, _msgSender());
        _removeAuthAddress(_id, _address, false, _msgSender());
    }

    function removeAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(checkBWO(_msgSender()), "Metaverse: address is not BWO");
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
                        keccak256("BWO(uint256 id,address addr,address sender,uint256 nonce,uint256 deadline)"),
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
        emit AuthAddressChanged(_id, _address, OperationEnum.REMOVE, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    function getAccountInfo(uint256 _id) public view returns (MetaverseStorage.Account memory account) {
        return metaStorage.getAccount(_id);
    }

    function getAccountAuthAddress(uint256 _id) public view returns (address[] memory) {
        return metaStorage.getAuthAddresses(_id);
    }

    /**
     * @dev See {IMetaverse-accountIsExist}.
     */
    function accountIsExist(uint256 _id) public view override returns (bool) {
        return getAccountInfo(_id).isExist;
    }

    /**
     * @dev See {IMetaverse-isFreeze}.
     */
    function isFreeze(uint256 _id) public view override returns (bool) {
        return getAccountInfo(_id).isFreeze;
    }

    /**
     * @dev See {IMetaverse-getOrCreateAccountId}.
     */
    function getOrCreateAccountId(address _address) public override returns (uint256 id) {
        if (_address != address(0) && getAccountIdByAddress(_address) == 0) {
            id = createAccount(_address, false);
        } else {
            id = getAccountIdByAddress(_address);
        }
    }

    /**
     * @dev See {IMetaverse-getAccountIdByAddress}.
     */
    function getAccountIdByAddress(address _address) public view override returns (uint256) {
        return metaStorage.authToId(_address);
    }

    /**
     * @dev See {IMetaverse-getAddressByAccountId}.
     */
    function getAddressByAccountId(uint256 _id) public view override returns (address) {
        return metaStorage.getAccountAddress(_id);
    }

    /**
     * @dev See {IMetaverse-checkSender}.
     */
    function checkSender(uint256 _id, address _sender) public view override {
        require(accountIsExist(_id), "Metaverse: Account does not exist");
        require(metaStorage.authAddressContains(_id, _sender), "Metaverse: Sender is not authorized");
    }

    function checkBWO(address _address) public view returns (bool) {
        return (metaStorage.isOperator(_address) || _owner == _address);
    }

    function getNonce(address _address) public view returns (uint256) {
        return metaStorage.nonces(_address);
    }

    function getTotalAccount() public view returns (uint256) {
        return metaStorage.totalAccount();
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function isOperator(address _address) public view returns (bool) {
        return metaStorage.isOperator(_address);
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "Metaverse: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "Metaverse: recoverSig failed");
    }

    function checkAddressIsNotUsed(address _address) internal view {
        require(getAccountIdByAddress(_address) == 0, "Metaverse: new address has been used");
    }

    function checkAddressIsNotZero(address _address) internal pure {
        require(_address != address(0), "Metaverse: address is zero");
    }
}
