//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IWorld.sol";
import "./interfaces/IWorldAsset.sol";
import "./interfaces/IItem721.sol";
import "./interfaces/ICash20.sol";
import "./mock/AvatarMock.sol";
import "./common/Ownable.sol";
import "./common/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract World is IWorld, Ownable, Initializable {
    enum AssetOperation {
        CASH20,
        ITEM721
    }
    // event 注册Asset
    event RegisterAsset(
        uint8 indexed operation,
        address indexed asset,
        string name,
        string image
    );

    // event 修改Asset
    event UpdateAsset(address indexed asset, string image);
    // event 创建Account
    event CreateAccount(uint256 indexed id, address indexed account);
    // event 修改Account
    event UpdateAccount(
        uint256 indexed id,
        address indexed newAddress,
        bool isTrust
    );
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event AddSafeContract(address indexed safeContract);
    event RemoveSafeContract(address indexed safeContract);
    event TrustContract(uint256 indexed id, address indexed safeContract);
    event UntrustContract(uint256 indexed id, address indexed safeContract);

    // avatar addr
    address private _avatar;
    // avatar max id
    uint256 private _avatarMaxId;
    // account Id
    uint256 private _totalAccount;

    uint256 private constant MAX_ASSET_COUNT = 200;

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

    // Mapping from address to operator
    mapping(address => bool) private _isOperatorByAddress;

    // Mapping from address to trust contract
    mapping(address => bool) private _safeContracts;

    // Mapping from account Id to contract
    mapping(uint256 => mapping(address => bool))
        private _isTrustContractByAccountId;

    // Mapping from address to Asset
    mapping(address => Asset) private _assets;

    address[] private _assetAddresses;

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

    function registerAvatar(address avatar, string calldata _image)
        public
        onlyOwner
        initializer
    {
        _avatar = avatar;
        uint256 maxId = AvatarMock(_avatar).maxAvatar();
        _avatarMaxId = maxId;
        _totalAccount = maxId;
        registerAsset(avatar, AssetOperation.ITEM721, _image);
    }

    function getOrCreateAccountId(address _address)
        public
        virtual
        override
        onlyInitialized
        returns (uint256 id)
    {
        if (_addressesToIds[_address] == 0 && _address != address(0)) {
            id = createAccount(_address);
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
                _accountsById[IItem721(_avatar).ownerOfItem(_id)]._address
            ) {
                return true;
            }
        }
        return false;
    }

    function getAccountIdByAddress(address _address)
        public
        view
        virtual
        override
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
                : _accountsById[IItem721(_avatar).ownerOfItem(_id)]._address;
    }

    function registerAsset(
        address _contract,
        AssetOperation _operation,
        string calldata _image
    ) public onlyOwner {
        require(
            _assetAddresses.length < MAX_ASSET_COUNT,
            "World: max asset count"
        );
        require(_contract != address(0), "World: zero address");
        require(_assets[_contract]._isExist == false, "World: asset is exist");
        require(
            address(this) == IWorldAsset(_contract).worldAddress(),
            "World: world address is not match"
        );

        string memory symbol = IWorldAsset(_contract).symbol();
        _assets[_contract] = Asset(
            uint8(_operation),
            true,
            _contract,
            symbol,
            _image
        );
        _assetAddresses.push(_contract);
        emit RegisterAsset(uint8(_operation), _contract, symbol, _image);
    }

    function updateAsset(
        address _contract,
        AssetOperation _typeOperation,
        string calldata _image
    ) public onlyOwner {
        require(
            _assets[_contract]._isExist == true,
            "World: asset is not exist"
        );
        require(
            _assets[_contract]._type == uint8(_typeOperation),
            "World: asset type is not match"
        );

        _assets[_contract]._image = _image;
        emit UpdateAsset(_contract, _image);
    }

    function createAccount(address _address)
        public
        onlyInitialized
        returns (uint256 id)
    {
        require(_address != address(0), "World: zero address");
        require(_addressesToIds[_address] == 0, "World: address is exist");
        _totalAccount++;
        id = _totalAccount;
        _accountsById[id] = Account(false, true, id, _address);
        _addressesToIds[_address] = id;
        emit CreateAccount(id, _address);
    }

    function changeAccount(
        uint256 _id,
        address _newAddress,
        bool _isTrustWorld
    ) public onlyOwner {
        require(
            _accountsById[_id]._isExist == true,
            "World: account is not exist"
        );
        address oldAddress = _accountsById[_id]._address;
        if (oldAddress != _newAddress) {
            _accountsById[_id]._address = _newAddress;
            _addressesToIds[_newAddress] = _id;
            delete _addressesToIds[oldAddress];
        }
        _accountsById[_id]._isTrustWorld = _isTrustWorld;
        emit UpdateAccount(_id, _newAddress, _isTrustWorld);
    }

    function trustContract(uint256 _id, address _contract) public {
        require(
            _accountsById[_id]._address == msg.sender,
            "World: sender not account owner"
        );
        require(
            _safeContracts[_contract] == true,
            "World: contract is not safe"
        );
        _isTrustContractByAccountId[_id][_contract] = true;
        emit TrustContract(_id, _contract);
    }

    function untrustContract(uint256 _id, address _contract) public {
        require(
            _accountsById[_id]._address == msg.sender,
            "World: sender not account owner"
        );
        require(
            _safeContracts[_contract] == true,
            "World: contract is not safe"
        );

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

    // 添加contract
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

    function isSafeContract(address _contract) public view returns (bool) {
        return _safeContracts[_contract];
    }

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
