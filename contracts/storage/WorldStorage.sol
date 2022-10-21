//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IAsset.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IAcertContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorldStorage is IAcertContract, Ownable {
    // struct Asset
    struct Asset {
        bool isExist;
        bool isEnabled;
        address addr;
        IAsset.ProtocolEnum _protocol;
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
    mapping(uint256 => mapping(address => bool)) public isTrustContractByAccountId;
    // Mapping from address to Asset
    mapping(address => Asset) public assets;
    // Mapping from is trust world
    mapping(uint256 => bool) public isTrustWorld;
    // nonce
    mapping(address => uint256) public nonces;

    mapping(address => bool) public isOperator;

    address public world;

    constructor() {
    }

    modifier onlyWorld() {
        require(world == msg.sender);
        _;
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return address(IAcertContract(world).metaverseAddress());
    }

    function updateWorld(address _address) public onlyOwner {
        require(_address != address(0));
        world = _address;
    }

    function setOperator(address _operator, bool _isOperator) public onlyWorld {
        isOperator[_operator] = _isOperator;
    }

    function IncrementNonce(address _sender) public onlyWorld {
        nonces[_sender]++;
    }

    function getAsset(address _address) public view returns (Asset memory) {
        return assets[_address];
    }

    function setAsset(address _address) public onlyWorld {
        IAsset.ProtocolEnum protocol = IAsset(_address).protocol();
        assets[_address] = Asset(true, true, _address, protocol);
    }

    function updateAsset(address _address, bool _enabled) public onlyWorld {
        require(assets[_address].isExist == true, "World: asset is not exist");
        assets[_address].isEnabled = _enabled;
    }

    function addSafeContract(address _address, string calldata _name) public onlyWorld {
        safeContracts[_address] = Contract(true, _address, _name);
    }

    function removeSafeContract(address _address) public onlyWorld {
        require(safeContracts[_address].isExist == true, "World: safeContract is not exist");
        safeContracts[_address].isExist = false;
    }

    function getSafeContract(address _address) public view returns (Contract memory) {
        return safeContracts[_address];
    }

    function setTrustContractByAccountId(
        uint256 _accountId,
        address _address,
        bool _isTrust
    ) public onlyWorld {
        isTrustContractByAccountId[_accountId][_address] = _isTrust;
    }

    function setTrustWorld(uint256 _accountId, bool _isTrust) public onlyWorld {
        isTrustWorld[_accountId] = _isTrust;
    }
}
