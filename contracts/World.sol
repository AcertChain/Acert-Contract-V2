//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./common/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./token/Item.sol";

contract World is Context, Ownable, Item {
    // constructor
    constructor() {
        _owner = _msgSender();
    }

    // event 注册cash
    event RegisterCash(
        address _contract,
        string _name,
        string _image,
        string _symbol
    );
    // event 注册item
    event RegisterItem(
        address _contract,
        string _name,
        string _image,
        string _symbol
    );
    // event _worldOwner修改Asset  _contract
    event ChangeAsset(address _worldOwner, address _contract, string _symbol);
    // event _worldOwner修改Asset  _name
    event ChangeAssetName(address _worldOwner, string _symbol, string _name);
    // event _worldOwner修改Asset  _image
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
        string _symbol;
        uint8 _standard;
        address _contract;
        string _name;
        string _image;
    }

    // avatar最大数量
    uint256 public constant MAX_AVATAR_INDEX = 100000;

    // func 注册cash
    function registerCash(
        string calldata _symbol,
        address _contract,
        string calldata _name,
        string calldata _image
    ) public onlyOwner {}

    // func 注册item
    function registerItem(
        string calldata _symbol,
        address _contract,
        string calldata _name,
        string calldata _image
    ) public onlyOwner {}

    // func 修改Asset _contract
    function changeAsset(
        string calldata _symbol,
        address _contract
    ) public onlyOwner {}

    // func 修改Asset _name
    function changeAssetName(
        string calldata _symbol,
        string calldata _name
    ) public onlyOwner {}

    // func 修改Asset _image
    function changeAssetImage(
        string calldata _symbol,
        string calldata _image
    ) public onlyOwner {}

    // func 创建Account
    function createAccount(address _address) public {}

    // func 获取Account ID，如果没有对应Account则创建Account
    function getOrCreateAccountID(address _address) public returns (uint256 id) {}

    // func 修改Account _address
    function changeAccount(
        uint256 _id,
        address _newAddress
    ) public onlyOwner {}

    // func 修改Account _isTrustAdmin
    function changeAccountTrustAdmin(uint256 _id, bool _trust) public {}

    // func 修改Account _level
    function changeAccountLevel(uint256 _id, uint256 _level) public onlyOwner {}

    // func 获取Account
    function getAccount(uint256 _id) public view returns (Account memory) {}

    // func 通过_address 获取Account
    function getAccountByAddress(address _address) public view returns (Account memory) {}

    // func 判断Holder是否为Avatar
    function isAvatar(uint256 _id) public view returns (bool isAvatar) {}

    // func 判断Holder（Avatar或者Account）是否存在
    function holderExist(uint256 _id) public view returns (bool exist) {}

    // func 获取Asset
    function getAsset(string calldata _symbol) public view returns (Asset memory) {}

}
