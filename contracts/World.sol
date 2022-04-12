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
    // event 修改Account _address
    event ChangeAccount(
        uint256 _id, 
        address _executor,
        bool _isWorldOwner,
        address _newAddress
    );
    // event 修改Account _isTrustAdmin
    event ChangeAccountTrustAdmin(
        uint256 _id, 
        address _executor,
        bool _isWorldOwner,
        bool _isTrustAdmin
    );
    // event 修改Account _level
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
        uint8 _standard;
        address _contract;
        string _name;
        string _image;
        string _symbol;
    }

    // avatar最大数量
    uint256 public constant MAX_AVATAR_COUNT = 100000;

    // func 注册cash
    function registerCash(
        address _contract,
        string calldata _name,
        string calldata _image,
        string calldata _symbol
    ) public onlyOwner {}

    // func 注册item
    function registerItem(
        address _contract,
        string calldata _name,
        string calldata _image,
        string calldata _symbol
    ) public onlyOwner {}

    // func 修改Asset _contract
    function changeAsset(
        address _worldOwner,
        address _contract,
        string calldata _symbol
    ) public onlyOwner {}

    // func 修改Asset _name
    function changeAssetName(
        address _worldOwner,
        string calldata _symbol,
        string calldata _name
    ) public onlyOwner {}

    // func 修改Asset _image
    function changeAssetImage(
        address _worldOwner,
        string calldata _symbol,
        string calldata _image
    ) public onlyOwner {}

    // func 创建Account
    function createAccount(address _address) public {}

    // func 修改Account _address
    function changeAccount(
        address _newAddress
    ) public onlyOwner {}

    // func 修改Account _isTrustAdmin
    function changeAccountTrustAdmin(uint256 _id, bool _trust) public {}

    // func 修改Account _level
    function changeAccountLevel(uint256 _level) public onlyOwner {}

    // func 获取Account
    function getAccount(address _address) public view returns (Account memory) {}

    // func 获取Asset
    function getAsset(string calldata _symbol) public view returns (Asset memory) {}

}
