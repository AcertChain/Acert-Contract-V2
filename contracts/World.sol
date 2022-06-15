//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IWorld.sol";
import "./interfaces/IWorldAsset.sol";
import "./interfaces/IItem721.sol";
import "./interfaces/ICash20.sol";
import "./Metaverse.sol";
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

    event UpdateAsset(address indexed asset, string image);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event AddSafeContract(address indexed safeContract);
    event RemoveSafeContract(address indexed safeContract);
    event TrustContract(uint256 indexed id, address indexed safeContract);
    event UntrustContract(uint256 indexed id, address indexed safeContract);

    // struct Asset
    struct Asset {
        uint8 _type;
        bool _isExist;
        address _contract;
        string _name;
        string _image;
    }

    // Mapping from address to operator
    mapping(address => bool) private _isOperatorByAddress;

    // Mapping from address to trust contract
    mapping(address => bool) private _safeContracts;

    // Mapping from account Id to contract
    mapping(uint256 => mapping(address => bool))
        private _isTrustContractByAccountId;

    mapping(uint256 => bool) private _isTrustWorld;

    // Mapping from address to Asset
    mapping(address => Asset) private _assets;

    address[] private _assetAddresses;

    address private _metaverse;

    // constructor
    constructor(address metaverse) {
        _owner = msg.sender;
        _metaverse = metaverse;
    }

    function registerAsset(
        address _contract,
        AssetOperation _operation,
        string calldata _image
    ) public onlyOwner {
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

    function trustContract(uint256 _id, address _contract) public {
        require(
            Metaverse(_metaverse).getAddressById(_id) == msg.sender,
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
            getAddressById(_id) == msg.sender,
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
        return _isTrustWorld[_id];
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
        if (_isTrustWorld[_id] == true) {
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

    function getMetaverse() public view returns (address) {
        return _metaverse;
    }

    function checkAddress(address _address, uint256 _id)
        public
        view
        override
        returns (bool)
    {
        return Metaverse(_metaverse).checkAddress(_address, _id);
    }

    function getAccountIdByAddress(address _address)
        public
        view
        override
        returns (uint256)
    {
        return Metaverse(_metaverse).getIdByAddress(_address);
    }

    function getAddressById(uint256 _id) public view override returns (address) {
        return Metaverse(_metaverse).getAddressById(_id);
    }

    function isFreeze(uint256 _id) public view  returns (bool) {
        return Metaverse(_metaverse).isFreeze(_id);
    }

    function getOrCreateAccountId(address _address)
        public
        override
        returns (uint256 id)
    {
        return Metaverse(_metaverse).getOrCreateAccountId(_address);
    }
}
