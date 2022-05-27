//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IWorld.sol";
import "./interfaces/IWorldAsset.sol";
import "./interfaces/IItem721.sol";
import "./mock/AvatarMock.sol";
import "./common/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


contract World is IWorld, Ownable {
    enum AssetOperation {
        CASH20,
        ITEM721
    }
    // event 注册Asset
    event RegisterAsset(
        uint8 operation,
        address asset,
        string name,
        string image
    );

    // event 修改Asset
    event UpdateAsset(address asset, string image);
    // event 创建Account
    event CreateAccount(uint256 id, address account);
    // event 修改Account 
    event UpdateAccount(
        uint256 id,
        address executor,
        address newAddress,
        bool isTrust
    );
    event AddOperator(address operator);
    event RemoveOperator(address operator);
    event AddSafeContract(address safeContract);
    event RemoveSafeContract(address safeContract);
    event TrustContract(uint256 id, address safeContract);
    event UntrustContract(uint256 id, address safeContract);

    // avatar addr
    address private _avatar;
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
        address _preAddress;
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

    function registerAvatar(
        address avatar,
        string calldata name,
        string calldata image
    ) public onlyOwner {
        require(avatar != address(0), "World: zero address");
        _avatar = avatar;
        _assets[_avatar] = Asset(
            uint8(AssetOperation.ITEM721),
            true,
            _avatar,
            name,
            image
        );
        uint256 maxId = AvatarMock(_avatar).maxAvatar();
        _avatarMaxId = maxId;
        _totalAccount = maxId;
        emit RegisterAsset(uint8(AssetOperation.ITEM721), _avatar, name, image);
    }

    function getOrCreateAccountId(address _address)
        public
        virtual
        override
        returns (uint256 id)
    {
        if (_addressesToIds[_address] == 0) {
            _totalAccount++;
            id = _totalAccount;
            _accountsById[id] = Account(false, true, id, _address, address(0));
            _addressesToIds[_address] = id;
            emit CreateAccount(id, _address);
        } else {
            id = _addressesToIds[_address];
        }
    }

    function checkAddress(address _address, uint256 _id)
        public
        virtual
        override
        returns (bool)
    {
        // 检查address 和 id是否匹配 ，如果匹配，返回true ，否则返回false
        if (_id > _avatarMaxId) {
            if (_accountsById[_id]._address == _address) {
                return true;
            }
        } else {
            if (
                _address ==
                _accountsById[IItem721(_avatar).ownerOfId(_id)]._address
            ) {
                return true;
            }
        }
        return false;
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
        returns (address)
    {
        return
            (_id > _avatarMaxId || _id == 0)
                ? _accountsById[_id]._address
                : _accountsById[IItem721(_avatar).ownerOfId(_id)]._address;
    }

    function registerAsset(
        address _contract,
        AssetOperation _operation,
        string calldata _image
    ) public onlyOwner {
        require(_contract != address(0), "World: zero address");
        require(_assets[_contract]._isExist == false, "World: asset is exist");
        // 这个一步校验了world的address是否是相同的
        require(address(this) == IWorldAsset(_contract).worldAddress(), "World: world address is not match");
       
        string memory symbol = IWorldAsset(_contract).symbol();
        _assets[_contract] = Asset(
            uint8(_operation),
            true,
            _contract,
            symbol,
            _image
        );
        emit RegisterAsset(uint8(_operation), _contract, symbol, _image);
    }

    function updateAsset(
        address _contract,
        AssetOperation _typeOperation,
        string calldata _image
    ) public onlyOwner {
        require( _assets[_contract]._isExist == true,"World: asset is not exist");
        require(_assets[_contract]._type == uint8(_typeOperation),"World: asset type is not match");
     
        _assets[_contract]._image = _image;
        emit UpdateAsset(_contract, _image);
    }

    function createAccount(address _address) public {
        require(_address != address(0), "World: zero address");
        require(_addressesToIds[_address] == 0, "World: address is exist");

        _totalAccount++;
        uint256 id = _totalAccount;
        _accountsById[id] = Account(false, true, id, _address, address(0));
        _addressesToIds[_address] = id;
        emit CreateAccount(id, _address);
    }

    function changeAccount(
        uint256 _id,
        address _newAddress,
        bool _isTrustWorld
    ) public onlyOwner {
        require(_accountsById[_id]._isExist == true,"World: account is not exist");
        require(_addressesToIds[_newAddress] == 0, "World: address is exist");

        address old = _accountsById[_id]._address;
        if (old != _newAddress) {
            _accountsById[_id]._preAddress = old;
            _accountsById[_id]._address = _newAddress;
            _addressesToIds[_newAddress] = _id;
            delete _addressesToIds[old];
        }
        _accountsById[_id]._isTrustWorld = _isTrustWorld;
        emit UpdateAccount(_id, msg.sender, _newAddress, _isTrustWorld);
    }

    function changeAssertAccountAddress(Change[] calldata _changes)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _changes.length; i++) {
            require(_assets[_changes[i]._asset]._isExist == true,"World: asset is not exist");
            require(_accountsById[_changes[i]._accountId]._isExist == true,"World: account is not exist");

            IAsset(_changes[i]._asset).updateAccountAddress(
                _changes[i]._accountId,
                _accountsById[_changes[i]._accountId]._address,
                _accountsById[_changes[i]._accountId]._preAddress
            );
        }
    }

    function trustContract(uint256 _id, address _contract) public {
        require(_accountsById[_id]._address == msg.sender,"World: sender not account owner");
        require(_safeContracts[_contract] == true,"World: contract is not safe");
        _isTrustContractByAccountId[_id][_contract] = true;
        emit TrustContract(_id, _contract);
    }

    function untrustContract(uint256 _id, address _contract) public {
        require(_accountsById[_id]._address == msg.sender,"World: sender not account owner");
        require(_safeContracts[_contract] == true,"World: contract is not safe");

        delete _isTrustContractByAccountId[_id][_contract];
        emit UntrustContract(_id, _contract);
    }

    // 添加operator
    function addOperator(address _operator) public onlyOwner {
        require(_operator != address(0), "World: zero address");
        _isOperatorByAddress[_operator] = true;
        emit AddOperator(_operator);
    }

    // 删除operator
    function removeOperator(address _operator) public onlyOwner {
        delete _isOperatorByAddress[_operator];
        emit RemoveOperator(_operator);
    }

    // is operator
    function isOperator(address _operator) public view returns (bool) {
        return _isOperatorByAddress[_operator];
    }

    // 添加conttract
    function addContract(address _contract) public onlyOwner {
        require(_contract != address(0), "World: zero address");
        _safeContracts[_contract] = true;
        emit AddSafeContract(_contract);
    }

    // 删除contract
    function removeContract(address _contract) public onlyOwner {
        delete _safeContracts[_contract];
        emit RemoveSafeContract(_contract);
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
