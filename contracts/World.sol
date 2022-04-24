//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./common/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IItem721.sol";
import "./interfaces/IWorld.sol";

contract World is Context, Ownable, IItem721, IWorld {
    using Address for address;
    using Strings for uint256;

    //  name
    string private _name;
    //  symbol
    string private _symbol;

    // constructor
    constructor(
        string memory name_,
        string memory symbol_,
        string memory version_
    ) {
        _name = name_;
        _symbol = symbol_;
        _owner = _msgSender();
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    enum TypeOperation {
        CASH,
        ITEM
    }

    // event 注册cash
    event RegisterCash(
        uint8 _type,
        address _contract,
        string _name,
        string _image
    );

    // event 注册item
    event RegisterItem(
       uint8 _type,
        address _contract,
        string _name,
        string _image
    );

    // event _worldOwner修改Asset _contract
    event ChangeAsset(address _worldOwner, address _contract, string _symbol);
    // event _worldOwner修改Asset _name
    event ChangeAssetName(address _worldOwner, string _symbol, string _name);
    // event _worldOwner修改Asset _image
    event ChangeAssetImage(address _worldOwner, string _symbol, string _image);
    // event 创建Account
    event CreateAccount(uint256 _id, address _address);
    // event _worldOwner修改Account _address
    event ChangeAccount(
        address _worldOwner,
        uint256 _id,
        address _executor,
        address _newAddress
    );
    // event 修改Account _isTrustAdmin
    event ChangeAccountTrustAdmin(
        uint256 _id,
        address _executor,
        bool _isTrustAdmin
    );
    // event _worldOwner修改Account _level
    event ChangeAccountLevel(address _worldOwner, uint256 _id, uint256 _level);

    // struct Account
    struct Account {
        uint256 _id;
        uint8 _level;
        bool _isTrustAdmin;
        address _address;
    }

    // struct Asset
    struct Asset {
        uint8 _type;
        bool _isExist;
        address _contract;
        string _name;
        string _image;
    }

    // avatar最大数量
    uint256 public constant MAX_AVATAR_INDEX = 100000;

    // 全局资产
    mapping(address => Asset) public _assets;

    // func 注册cash
    function registerCash(
        address _contract,
        string calldata _tokneName,
        string calldata _image
    ) public onlyOwner {
        require(
            _contract != address(0)&& _assets[_contract]._isExist == false,
            "contract is invalid"
        );
        
        Asset memory asset = Asset(
            uint8(TypeOperation.CASH),
            true,
            _contract,
            _tokneName,
            _image
        );

        _assets[_contract] = asset;
        emit RegisterCash(uint8(TypeOperation.CASH) ,_contract, _name, _image);
    }

    // func 注册item
    function registerItem(
        address _contract,
        string calldata _tokneName,
        string calldata _image
    ) public onlyOwner {
         require(
            _contract != address(0)&& _assets[_contract]._isExist == false,
            "contract is invalid"
        );
        
        Asset memory asset = Asset(
            uint8(TypeOperation.ITEM),
            true,
            _contract,
            _tokneName,
            _image
        );

        _assets[_contract] = asset;
        emit RegisterItem(uint8(TypeOperation.ITEM) ,_contract, _name, _image);
    }

    // func 修改Asset _contract
    function changeAsset(string calldata _symbol, address _contract)
        public
        onlyOwner
    {}

    // func 修改Asset _name
    function changeAssetName(string calldata _symbol, string calldata _name)
        public
        onlyOwner
    {}

    // func 修改Asset _image
    function changeAssetImage(string calldata _symbol, string calldata _image)
        public
        onlyOwner
    {}

    // func 创建Account
    function createAccount(address _address) public {}

    // func 获取Account ID，如果没有对应Account则创建Account
    function getOrCreateAccountID(address _address)
        public
        returns (uint256 id)
    {}

    // func 修改Account _address
    function changeAccount(uint256 _id, address _newAddress) public onlyOwner {}

    // func 修改Account _isTrustAdmin
    function changeAccountTrustAdmin(uint256 _id, bool _trust) public {}

    // func 修改Account _level
    function changeAccountLevel(uint256 _id, uint256 _level) public onlyOwner {}

    // func 获取Account
    function getAccount(uint256 _id) public view returns (Account memory) {}

    // func 通过_address 获取Account
    function getAccountByAddress(address _address)
        public
        view
        returns (Account memory)
    {}

    // func 判断Holder是否为Avatar
    function isAvatar(uint256 _id) public view returns (bool isAvatar) {}

    // func 判断Holder（Avatar或者Account）是否存在
    function holderExist(uint256 _id) public view returns (bool exist) {}

    // func 获取Asset
    function getAsset(string calldata _symbol)
        public
        view
        returns (Asset memory)
    {}
}
