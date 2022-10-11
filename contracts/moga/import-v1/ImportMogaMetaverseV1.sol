//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../common/Ownable.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IApplyStorage.sol";
import "../interfaces/IMetaverse.sol";
import "../storage/MetaverseStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract ImportMogaMetaverseV1 is IMetaverse, IApplyStorage, Context, Ownable, EIP712 {
    enum OperationEnum {
        ADD,
        REMOVE
    }
    event RegisterWorld(address indexed world, string name, address indexed storageAddress);
    event DisableWorld(address indexed world);
    event SetAdmin(address indexed admin);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event CreateAccount(uint256 indexed accountId, address indexed authAddress, bool isTrustAdmin);
    event TrustAdmin(uint256 indexed accountId, bool isTrustAdmin, bool isBWO, address indexed Sender, uint256 nonce);
    event FreezeAccount(uint256 indexed accountId, bool isBWO, address indexed Sender, uint256 nonce);
    event UnFreezeAccount(uint256 indexed accountId);
    event AuthAddressChanged(
        uint256 indexed accountId,
        address indexed authAddress,
        OperationEnum operation,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    string public name;
    address public admin;
    uint256 public immutable startId;
    MetaverseStorage public metaStorage;
    uint256 public totalAccount;


    constructor(
        string memory name_,
        string memory version_,
        uint256 startId_,
        address metaStorage_
    ) EIP712(name_, version_) {
        name = name_;
        _owner = _msgSender();
        startId = startId_;
        metaStorage = MetaverseStorage(metaStorage_);
    }

    /**
     * @dev See {IApplyStorage-getStorageAddress}.
     */
    function getStorageAddress() external view returns (address) {
        return address(metaStorage);
    }

    function registerWorld(address _world) public onlyOwner {
        checkAddressIsNotZero(_world);
        require(containsWorld(_world) == false, "Metaverse: world is exist");
        require(IWorld(_world).getMetaverse() == address(this), "Metaverse: metaverse is not match");
        string _name = IWorld(_world).name;
        metaStorage.add(_world, _name);
        string storageAddress = IApplyStorage(_world).getStorageAddress;
        emit RegisterWorld(_world, _name, storageAddress);
    }

    function containsWorld(address _world) public view returns (bool) {
        return metaStorage.contains(_world);
    }


    function createAccount(address _address, bool _isTrustAdmin) public onlyOwner returns (uint256 id) {
        checkAddressIsNotZero(_address);
        checkAddressIsNotUsed(_address);
        totalAccount++;
        id = totalAccount + startId;
        metaStorage.setAccount(MetaverseStorage.Account(true, _isTrustAdmin, false, id));
        metaStorage.addAuthAddress(id, _address);
        emit CreateAccount(id, _address, _isTrustAdmin);
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
    function accountIsExist(uint256 _id) public view returns (bool) {
        return getAccountInfo(_id).isExist;
    }

    /**
     * @dev See {IMetaverse-isFreeze}.
     */
    function isFreeze(uint256 _id) public view returns (bool) {
        return false;
    }

    /**
     * @dev See {IMetaverse-getOrCreateAccountId}.
     */
    function getOrCreateAccountId(address _address) public returns (uint256 id) {
        require(false, "Metaverse: not support getOrCreateAccountId");
    }

    /**
     * @dev See {IMetaverse-getAccountIdByAddress}.
     */
    function getAccountIdByAddress(address _address) public view returns (uint256) {
        return metaStorage.authToId(_address);
    }

    /**
     * @dev See {IMetaverse-getAddressByAccountId}.
     */
    function getAddressByAccountId(uint256 _id) public view returns (address) {
        require(accountIsExist(_id), "Metaverse: Account does not exist");
        return metaStorage.getAccountAddress(_id);
    }

    /**
     * @dev See {IMetaverse-checkSender}.
     */
    function checkSender(uint256 _id, address _sender) public view {
        require(false, "Metaverse: not support non-owner");
    }

    function checkAddressIsNotUsed(address _address) internal view {
        require(getAccountIdByAddress(_address) == 0, "Metaverse: new address has been used");
    }

    function checkAddressIsNotZero(address _address) internal pure {
        require(_address != address(0), "Metaverse: address is zero");
    }
}
