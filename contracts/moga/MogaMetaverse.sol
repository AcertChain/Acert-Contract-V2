//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../common/Ownable.sol";
import "./MonsterGalaxy.sol";
import "../storage/MetaverseStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract MogaMetaverse is Ownable, EIP712 {
    event RegisterWorld(address indexed world, string name);
    event DisableWorld(address indexed world);
    event SetAdmin(address indexed admin);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event CreateAccount(
        uint256 indexed accountId,
        address indexed authAddress,
        bool isTrustAdmin
    );
    event TrustAdmin(
        uint256 indexed accountId,
        bool isTrustAdmin,
        bool isBWO,
        address indexed Sender,
        uint256 nonce
    );
    event FreezeAccount(
        uint256 indexed accountId,
        bool isBWO,
        address indexed Sender,
        uint256 nonce
    );
    event UnFreezeAccount(
        uint256 indexed accountId
    );
    event AddAuthAddress(
        uint256 indexed accountId,
        address indexed authAddress,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );
    event RemoveAuthAddress(
        uint256 indexed accountId,
        address indexed authAddress,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    address public admin;
    uint256 public immutable startId;
    MetaverseStorage public metaStorage;
    uint256 public totalAccount;

    // Mapping from address to operator
    mapping(address => bool) public isOperator;

    constructor(
        string memory name_,
        string memory version_,
        uint256 startId_,
        address metaStorage_
    ) EIP712(name_, version_) {
        _owner = msg.sender;
        startId = startId_;
        metaStorage = MetaverseStorage(metaStorage_);
    }

    function registerWorld(address _world, string calldata _name) public onlyOwner {
        checkAddressIsNotZero(_world);
        require(containsWorld(_world) == false, "Metaverse: world is exist");
        require(
            MonsterGalaxy(_world).getMetaverse() == address(this),
            "Metaverse: metaverse is not match"
        );
        metaStorage.add(_world,_name);
        emit RegisterWorld(_world, _name);
    }

    function disableWorld(address _world) public onlyOwner {
        checkAddressIsNotZero(_world);
        metaStorage.disableWorld(_world);
        emit DisableWorld(_world);
    }

    function getWorldInfo(address _world)
        public
        view
        returns (MetaverseStorage.WorldInfo memory)
    {
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
        admin = _address;
        emit SetAdmin(_address);
    }

    function addOperator(address _operator) public onlyOwner {
        checkAddressIsNotZero(_operator);
        isOperator[_operator] = true;
        emit AddOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner {
        delete isOperator[_operator];
        emit RemoveOperator(_operator);
    }

    function createAccount(address _address, bool _isTrustAdmin)
        public
        virtual
        returns (uint256 id)
    {
        checkAddressIsNotZero(_address);
        checkAddressIsNotUsed(_address);
        totalAccount++;
        id = totalAccount + startId;
        metaStorage.setAccount(
            MetaverseStorage.Account(true, _isTrustAdmin, false, id, _address)
        );
        metaStorage.addAddressToId(_address, id);
        emit CreateAccount(id, _address, _isTrustAdmin);
    }

    function trustAdmin(uint256 _id, bool _isTrustAdmin) public {
        checkSender(_id, msg.sender);
        _trustAdmin(_id, _isTrustAdmin, false, msg.sender);
    }

    function trustAdminBWO(
        uint256 _id,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        checkBWO(msg.sender);
        trustAdminBWOParamsVerify(
            _id,
            _isTrustAdmin,
            sender,
            deadline,
            signature
        );
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
                            "BWO(uint256 id,address new,bool isTrustAdmin,address sender,uint256 nonce,uint256 deadline)"
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
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isExist == true, "Metaverse: account is not exist");
        account.isTrustAdmin = _isTrustAdmin;
        metaStorage.setAccount(account);
        emit TrustAdmin(_id, _isTrustAdmin, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    function freezeAccount(uint256 _id) public {
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        if (msg.sender == admin && getAccountIdByAddress(msg.sender != _id)) {
            require(
                (account.isTrustAdmin),
                "Metaverse: admin does not have permission to freeze the account"
            );
        } else {
            checkSender(_id, msg.sender);
        }
        _freezeAccount(_id, false, msg.sender);
    }

    function freezeAccountBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        checkBWO(msg.sender);
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
                        keccak256(
                            "BWO(uint256 id,address sender,uint256 nonce,uint256 deadline)"
                        ),
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
        require(
            account.isFreeze == false,
            "Metaverse: The account has been frozen"
        );
        account.isFreeze = true;
        metaStorage.setAccount(account);
        emit FreezeAccount(_id, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    function unfreezeAccount(uint256 _id) public {
        require(msg.sender == admin, "Metaverse: sender is not admin");
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isFreeze, "Metaverse: The accounts were not frozen");
        account.isFreeze = false;
        emit UnFreezeAccount(_id);
    }

    function addAuthAddress(uint256 _id, address _address) public {
        checkSender(_id, msg.sender);
        _addAuthAddress(_id, _address, false, msg.sender);
    }

    function addAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        checkBWO(msg.sender);
        addAuthAddressBWOParamsVerfiy(
            _id,
            _address,
            sender,
            deadline,
            signature
        );
        _addAuthAddressBWO(_id, _address, true, sender);
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
                            "BWO(uint256 id,address addr,address sender,uint256 nonce,uint256 deadline)"
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

    function _addAuthAddressBWO(
        uint256 _id,
        address _address,
        bool _isBWO,
        address _sender
    ) private {
        metaStorage.addAuthAddress(_id, _address);

        emit AddAuthAddressBWO(_id, _address, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    function removeAuthAddress(uint256 _id, address _address) public {
        checkSender(_id, msg.sender);
        _removeAuthAddress(_id, _address, false, msg.sender);
    }

    function removeAuthAddressBWO(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        checkBWO(msg.sender);
        removeAuthAddressBWOParamsVerfiy(
            _id,
            _address,
            sender,
            deadline,
            signature
        );
        _removeAuthAddressBWO(_id, _address, true, sender);
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
                            "BWO(uint256 id,address addr,address sender,uint256 nonce,uint256 deadline)"
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

    function _removeAuthAddressBWO(
        uint256 _id,
        address _address,
        bool _isBWO,
        address _sender
    ) private {
        metaStorage.removeAuthAddress(_id, _address);
        emit RemoveAuthAddressBWO(_id, _address, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    function getAccountInfo(uint256 _id)
        public
        view
        returns (MetaverseStorage.Account memory account)
    {
        return metaStorage.getAccount(_id);
    }

    function getAccountAuthAddress(uint256 _id) public view returns (address) {
        return metaStorage.getAuthAddress(_id);
        // todo 似乎有用
    }

    function authToAddress(address _address) public view returns (uint256) {
        return metaStorage.authToAddress(_address);
        // todo 似乎没用
    }

    /**
     * @dev See {IMetaverse-accountIsExist}.
     */
    function accountIsExist(uint256 _id) internal view returns (bool) {
        return getAccountInfo(_id).isExist;
    }

    /**
     * @dev See {IMetaverse-isFreeze}.
     */
    function isFreeze(uint256 _id) public view returns (bool) {
        return getAccountInfo(_id).isFreeze;
    }

    /**
     * @dev See {IMetaverse-getOrCreateAccountId}.
     */
    function getOrCreateAccountId(address _address)
        public
        returns (uint256 id)
    {
        checkAddressIsNotZero(_address);
        if (getAccountIdByAddress(_address) == 0) {
            id = createAccount(_address, false);
        } else {
            id = getAccountIdByAddress(_address);
        }
    }

    /**
     * @dev See {IMetaverse-getAccountIdByAddress}.
     */
    function getAccountIdByAddress(address _address) public view returns (uint256) {
        return metaStorage.addressToId(_address);
    }

    /**
     * @dev See {IMetaverse-getAddressByAccountId}.
     */
    function getAddressByAccountId(uint256 _id) public view returns (address) {
        return getAccountInfo(_id).addr;
    }

    /**
     * @dev See {IMetaverse-checkSender}.
     */
    function checkSender(uint256 _id, address _sender) public {
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isExist == true, "Metaverse: account is not exist");
        require(account.addr == _sender, "Metaverse: sender not owner");
        // todo 还没有改AuthAddress的逻辑
    }

    function checkBWO(address _address) internal view {
        require(
            (isOperator[_address] || _owner == _address),
            "Metaverse: address is not BWO"
        );
    }

    function getNonce(address _address) public view returns (uint256) {
        return metaStorage.nonces(_address);
    }
    
    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "Metaverse: BWO call expired");
        require(
            signer == ECDSA.recover(digest, signature),
            "Metaverse: recoverSig failed"
        );
    }

    function checkAddressIsNotUsed(address _address) internal pure {
        require(
            getAccountIdByAddress(_address) == 0,
            "Metaverse: new address has been used"
        );
    }

    function checkAddressIsNotZero(address _address) internal pure {
        require(_address != address(0), "Metaverse: address is zero");
    }
}
