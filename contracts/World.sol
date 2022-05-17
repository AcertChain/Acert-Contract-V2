//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IWorld.sol";
import "./interfaces/IAsset.sol";
import "./interfaces/IItem721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
W01:zero address
W02:contract is invalid or is exist
W03:world is not equal
W04:asset is invalid
W05:address is invalid or is exist
W06:only operator or world can exec
W07:empty data
W08:asset is invalid or is not exist
W09:account is invalid or is not exist
W10:only owner
W11:must safe contract
W12:address should equal
 */
contract World is IWorld {
    enum TypeOperation {
        CASH,
        ITEM
    }
    event ChangeOwner(address owner);
    // event 注册Asset
    event RegisterAsset(
        uint8 _type,
        address _contract,
        string _name,
        string _image
    );
    // event _worldOwner修改Asset _contract
    event ChangeAsset(address _contract, string _name, string _image);
    // event 创建Account
    event CreateAccount(uint256 _id, address _address);
    // event 修改Account _address
    event ChangeAccount(
        uint256 _id,
        address _executor,
        address _newAddress,
        bool _isTrust
    );
    // event add operator
    event AddOperator(address _operator);
    // event remove operator
    event RemoveOperator(address _operator);
    // event add contract
    event AddSafeContract(address _contract);
    // event remove contract
    event RemoveSafeContract(address _contract);
    // event trustContract
    event TrustContract(uint256 _id, address _contract);
    // event AccountCancelTrustContract
    event UntrustContract(uint256 _id, address _contract);

    // avatar
    address private _avatar;
    // owner
    address private _owner;
    // avatar max id
    uint256 private _avatarMaxId;
    // account Id
    uint256 private _totalAccount;

    // struct Asset
    struct Asset {
        uint8 _type;
        bool _isExist;
        address _contract;
        string _name;
        string _image;
    }

    // struct Account
    struct Account {
        bool _isTrustWorld;
        bool _isExist;
        uint256 _id;
        address _address;
    }

    struct Change {
        address _asset;
        uint256 _accountId;
    }

    // Mapping from address to operator
    mapping(address => bool) private _isOperatorByAddress;

    // Mapping from address to trust contract
    mapping(address => bool) private _safeContracts;

    // Mapping from account Id to contract
    mapping(uint256 => mapping(address => bool))
        private _isTrustContractByAccountId;

    // Mapping from address to Asset
    mapping(address => Asset) private _assets;

    // Mapping from account ID to Account
    mapping(uint256 => Account) private _accountsById;

    // Mapping from adress to account ID
    mapping(address => uint256) private _addressesToIds;

    // constructor
    constructor() {
        _owner = msg.sender;
    }

    function getTotalAccount() public view virtual returns (uint256) {
        return _totalAccount;
    }

    function getAvatarMaxId() public view virtual returns (uint256) {
        return _avatarMaxId;
    }

    function getAvatar() public view virtual returns (address) {
        return _avatar;
    }

    function getOwner() public view virtual returns (address) {
        return _owner;
    }

    function registerAvatar(
        uint256 totalSupply,
        address avatar,
        string calldata name,
        string calldata image
    ) public {
        onlyOwner();
        require(avatar != address(0), "empty address");
        _avatar = avatar;
        _assets[_avatar] = Asset(
            uint8(TypeOperation.ITEM),
            true,
            _avatar,
            name,
            image
        );
        _avatarMaxId = totalSupply;
        _totalAccount = totalSupply;

        emit RegisterAsset(uint8(TypeOperation.ITEM), _avatar, name, image);
    }

    function getOrCreateAccountId(address _address)
        public
        virtual
        override
        returns (uint256 id)
    {
        if (_addressesToIds[_address] == 0) {
            // create account
            _totalAccount++;
            id = _totalAccount;
            _accountsById[id] = Account(false, true, id, _address);
            _addressesToIds[_address] = id;
            emit CreateAccount(id, _address);
        } else {
            id = _addressesToIds[_address];
        }
    }

    function getIdByAddress(address _address, uint256 _id)
        public
        virtual
        override
        returns (bool isAvatar)

    {
        if (_id > _avatarMaxId) {
            require(_accountsById[_id]._address == _address, "W12");
            return false;
        } else {
            require(
                _address ==
                    _accountsById[IItem721(_avatar).ownerOfId(_id)]._address,
                "W12"
            );
            return true;
        }
    }

    function getAccountIdByAddress(address _address)
        public
        view
        returns (uint256)
    {
        return _addressesToIds[_address];
    }

    function getAddressById(uint256 _id)
        public
        view
        virtual
        override
        returns (address _address)
    {
        if (_id > _avatarMaxId || _id == 0) {
            _address = _accountsById[_id]._address;
        } else {
            console.log("get avatar id %s", _id);
            _address = _accountsById[IItem721(_avatar).ownerOfId(_id)]._address;
        }
    }

    // func 注册资产
    function registerAsset(
        address _contract,
        TypeOperation _typeOperation,
        string calldata _tokneName,
        string calldata _image
    ) public {
        onlyOwner();
        require(
            _contract != address(0) && _assets[_contract]._isExist == false,
            "W02"
        );
        require(address(this) == IAsset(_contract).worldAddress(), "W03");
        _assets[_contract] = Asset(
            uint8(_typeOperation),
            true,
            _contract,
            _tokneName,
            _image
        );
        emit RegisterAsset(
            uint8(_typeOperation),
            _contract,
            _tokneName,
            _image
        );
    }

    // func 修改Asset _contract
    function changeAsset(
        address _contract,
        TypeOperation _typeOperation,
        string calldata _tokneName,
        string calldata _image
    ) public {
        onlyOwner();
        require(
            _contract != address(0) &&
                _assets[_contract]._isExist == true &&
                _assets[_contract]._type == uint8(_typeOperation),
            "W04"
        );
        _assets[_contract]._name = _tokneName;
        _assets[_contract]._image = _image;
        emit ChangeAsset(_contract, _tokneName, _image);
    }

    // function callAsset(address _contract, bytes calldata _data)
    //     public
    //     returns (bool success)
    // {
    //     onlyOwner();
    //     require(
    //         _contract != address(0) && _assets[_contract]._isExist == true,
    //         "W05"
    //     );
    //     (success, ) = _contract.call(_data);
    // }

    // func 创建Account
    function createAccount(address _address) public {
        //console.log("createAccount %s %s", _address,_addressesToIds[_address]);
        require(
            _address != address(0) && _addressesToIds[_address] == 0,
            "W05"
        );
        _totalAccount++;
        uint256 id = _totalAccount;
        _accountsById[id] = Account(false, true, id, _address);
        _addressesToIds[_address] = id;
        emit CreateAccount(id, _address);
    }

    // func world修改Account _address
    function changeAccountByOperator(
        uint256 _id,
        address _newAddress,
        bool _isTrustWorld
    ) public {
        require(
            _isOperatorByAddress[msg.sender] == true || _owner == msg.sender,
            "W06"
        );
        _changeAccount(_id, _newAddress, _isTrustWorld);
    }

    function changeAssertAccountAddressByOperator(Change[] calldata _changes)
        public
    {
        require(
            _isOperatorByAddress[msg.sender] == true || _owner == msg.sender,
            "W06"
        );
        for (uint256 i = 0; i < _changes.length; i++) {
            require(
                _changes[i]._asset != address(0) &&
                    _assets[_changes[i]._asset]._isExist == true,
                "W08"
            );
            require(
                _accountsById[_changes[i]._accountId]._isExist == true,
                "W09"
            );
            IAsset(_changes[i]._asset).changeAccountAddress(
                _changes[i]._accountId,
                _accountsById[_changes[i]._accountId]._address
            );
        }
    }

    // func user修改Account _address
    function changeAccountByUser(
        uint256 _id,
        address _newAddress,
        bool _isTrustWorld
    ) public {
        require(_accountsById[_id]._address == msg.sender, "W09");
        _changeAccount(_id, _newAddress, _isTrustWorld);
    }

    function accountTrustContract(uint256 _id, address _contract) public {
        require(_accountsById[_id]._address == msg.sender, "W09");
        require(_safeContracts[_contract] == true, "W11");
        _isTrustContractByAccountId[_id][_contract] = true;
        emit TrustContract(_id, _contract);
    }

    function accountUntrustContract(uint256 _id, address _contract) public {
        require(_accountsById[_id]._address == msg.sender, "W09");
        require(_safeContracts[_contract] == true, "W11");
        delete _isTrustContractByAccountId[_id][_contract];
        emit UntrustContract(_id, _contract);
    }

    function _changeAccount(
        uint256 _id,
        address _newAddress,
        bool _isTrustWorld
    ) internal {
        require(_id != 0 && _accountsById[_id]._isExist == true, "W09");

        if (_accountsById[_id]._address != _newAddress) {
            require(_addressesToIds[_newAddress] == 0, "W09");
            delete _addressesToIds[_accountsById[_id]._address];
            _accountsById[_id]._address = _newAddress;
            _addressesToIds[_newAddress] = _id;
        }
        _accountsById[_id]._isTrustWorld = _isTrustWorld;

        emit ChangeAccount(_id, msg.sender, _newAddress, _isTrustWorld);
    }

    function changeAssetAccountAddressByUser(address[] calldata _assetAddrs)
        public
    {
        require(_assetAddrs.length > 0, "W07");
        uint256 id = _addressesToIds[msg.sender];
        for (uint256 i = 0; i < _assetAddrs.length; i++) {
            require(_assetAddrs[i] != address(0), "W01");
            IAsset(_assetAddrs[i]).changeAccountAddress(id, msg.sender);
        }
    }

    // 添加operator
    function addOperator(address _operator) public {
        onlyOwner();
        require(_operator != address(0), "W01");
        _isOperatorByAddress[_operator] = true;
        emit AddOperator(_operator);
    }

    // 删除operator
    function removeOperator(address _operator) public {
        onlyOwner();
        delete _isOperatorByAddress[_operator];
        emit RemoveOperator(_operator);
    }

    // is operator
    function isOperator(address _operator) public view returns (bool) {
        return _isOperatorByAddress[_operator];
    }

    // 添加conttract
    function addContract(address _contract) public {
        onlyOwner();
        require(_contract != address(0), "W01");
        _safeContracts[_contract] = true;
        emit AddSafeContract(_contract);
    }

    // 删除contract
    function removeContract(address _contract) public {
        onlyOwner();
        delete _safeContracts[_contract];
        emit RemoveSafeContract(_contract);
    }

    function onlyOwner() internal view {
        require(_owner == msg.sender, "W10");
    }

    function changeOwner(address newOwner) public {
        onlyOwner();
        _owner = newOwner;
        emit ChangeOwner(_owner);
    }

    // is contract
    function isSafeContract(address _contract) public view returns (bool) {
        return _safeContracts[_contract];
    }

    // func 获取Asset
    function getAsset(address _contract) public view returns (Asset memory) {
        return _assets[_contract];
    }

    function isTrustWorld(uint256 _id) public view returns (bool _isTrust) {
        return _accountsById[_id]._isTrustWorld;
    }

    function isTrust(address _contract, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrust)
    {
        if (_safeContracts[_contract] == false) {
            return false;
        }
        if (_accountsById[_id]._isTrustWorld == true) {
            return true;
        }
        if (_isTrustContractByAccountId[_id][_contract] == false) {
            return false;
        }
        return true;
    }

    function isBWO(address _addr) public view virtual override returns (bool) {
        return _isOperatorByAddress[_addr] || _owner == _addr;
    }
}
