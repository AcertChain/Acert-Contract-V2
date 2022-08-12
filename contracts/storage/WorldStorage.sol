//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../common/Ownable.sol";
import "../interfaces/IWorldAsset.sol";

contract WorldStorage is Ownable {
    // struct Asset
    struct Asset {
        bool isExist;
        bool isEnabled;
        address addr;
        string name;
        string image;
        IWorldAsset.ProtocolEnum _protocol;
    }

    // struct Contract
    struct Contract {
        bool isExist;
        address addr;
        string name;
    }

    // Mapping from address to trust contract
    mapping(address => Contract) public safeContracts;
    // Mapping from account Id to contract
    mapping(uint256 => mapping(address => bool))
        public isTrustContractByAccountId;
    // Mapping from address to Asset
    mapping(address => Asset) public assets;
    // Mapping from is trust world
    mapping(uint256 => bool) public isTrustWorld;
    // nonce
    mapping(address => uint256) public nonces;

    address public world;
    address[] public assetAddresses;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyWorld() {
        require(world == msg.sender);
        _;
    }

    function updateWorld(address addr) public onlyOwner {
        require(addr != address(0));
        world = addr;
    }

    function IncrementNonce(address sender) public onlyWorld {
        nonces[sender]++;
    }

    function getAsset(address addr) public view returns (Asset memory) {
        return assets[addr];
    }

    function addAsset(Asset memory asset) public onlyWorld {
        assets[asset.addr] = asset;
    }

    function addAssetAddress(address addr) public onlyWorld {
        assetAddresses.push(addr);
    }

    function addSafeContract(Contract memory _contract) public onlyWorld {
        safeContracts[_contract.addr] = _contract;
    }

    function getSafeContract(address addr)
        public
        view
        returns (Contract memory)
    {
        return safeContracts[addr];
    }

    function trustContractByAccountId(uint256 _accountId, address _addr)
        public
        onlyWorld
    {
        isTrustContractByAccountId[_accountId][_addr] = true;
    }

    function untrustContractByAccountId(uint256 _accountId, address _addr)
        public
        onlyWorld
    {
        isTrustContractByAccountId[_accountId][_addr] = false;
    }

    function trustWorld(uint256 _accountId) public onlyWorld {
        isTrustWorld[_accountId] = true;
    }

    function untrustWorld(uint256 _accountId) public onlyWorld {
        isTrustWorld[_accountId] = false;
    }
}
