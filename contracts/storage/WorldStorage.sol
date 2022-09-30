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

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyWorld() {
        require(world == msg.sender);
        _;
    }

    function updateWorld(address _address) public onlyOwner {
        require(_address != address(0));
        world = _address;
    }

    function IncrementNonce(address _sender) public onlyWorld {
        nonces[_sender]++;
    }

    function getAsset(address _address) public view returns (Asset memory) {
        return assets[_address];
    }

    function setAsset(address _address) public onlyWorld {
        IWorldAsset.ProtocolEnum protocol = IWorldAsset(_address).protocol();
        assets[_address] = Asset(true, true, _address, protocol);
    }

    function updateAsset(address _address, _enabled) public onlyWorld {
        require(assets[_address].isExist == true, "World: asset is not exist");
        assets[_address].isEnabled = _enabled;
    }

    function addSafeContract(address _address, string calldata _name) public onlyWorld {
        safeContracts[_contract.addr] = Contract(_address, _name);
    }

    function removeSafeContract(address _address) public onlyWorld {
        require(safeContracts[_address].isExist == true, "World: safeContract is not exist");
        safeContracts[_contract.addr].isExist = false;
    }

    function getSafeContract(address _address) public view returns (Contract memory)
    {
        return safeContracts[_address];
    }

    function setTrustContractByAccountId(uint256 _accountId, address _address, bool _isTrustContract)
        public
        onlyWorld
    {
        isTrustContractByAccountId[_accountId][_address] = _isTrustContract;
    }

    function setTrustWorld(uint256 _accountId, bool _isTrustWorld) public onlyWorld {
        isTrustWorld[_accountId] = _isTrustWorld;
    }
}
