//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./common/Ownable.sol";
import "./World.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Metaverse is Ownable, EIP712 {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private worlds;

    event SetAdmin(address indexed admin);
    event CreateAccount(uint256 indexed id, address indexed account);
    event UpdateAccount(
        uint256 indexed id,
        address indexed newAddress,
        bool isTrustAdmin
    );
    event FreezeAccount(uint256 indexed id);
    event UnFreezeAccount(uint256 indexed id);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event AddWorld(
        address indexed world,
        string name,
        string icon,
        string url,
        string description
    );
    event UpdateWorld(
        address indexed world,
        string name,
        string icon,
        string url,
        string description
    );
    event RemoveWorld(address indexed world);

    mapping(address => WorldInfo) private worldInfos;

    struct WorldInfo {
        address world;
        string name;
        string icon;
        string url;
        string description;
    }

    struct Account {
        bool _isExist;
        bool _isTrustAdmin;
        bool _isFreeze;
        uint256 _id;
        address _address;
    }

    // Mapping from account ID to Account
    mapping(uint256 => Account) private _accountsById;
    // Mapping from adress to account ID
    mapping(address => uint256) private _addressesToIds;
    // Mapping from address to operator
    mapping(address => bool) private _isOperatorByAddress;

    // nonce
    mapping(address => uint256) private _nonces;

    uint256 private _totalAccount;

    address private _admin;

    constructor(string memory name_, string memory version_)
        EIP712(name_, version_)
    {
        _owner = msg.sender;
    }

    function addWorld(
        address _world,
        string calldata _name,
        string calldata _icon,
        string calldata _url,
        string calldata _description
    ) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        require(worlds.contains(_world) == false, "Metaverse: world is exist");
        require(
            World(_world).getMetaverse() == address(this),
            "Metaverse: metaverse is not match"
        );
        worlds.add(_world);
        worldInfos[_world] = WorldInfo({
            world: _world,
            name: _name,
            icon: _icon,
            url: _url,
            description: _description
        });
        emit AddWorld(_world, _name, _icon, _url, _description);
    }

    function removeWorld(address _world) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        if (worlds.contains(_world)) {
            worlds.remove(_world);
            delete worldInfos[_world];
            emit RemoveWorld(_world);
        }
    }

    function updateWorldInfo(
        address _world,
        string calldata _name,
        string calldata _icon,
        string calldata _url,
        string calldata _description
    ) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        if (worlds.contains(_world)) {
            worldInfos[_world] = WorldInfo({
                world: _world,
                name: _name,
                icon: _icon,
                url: _url,
                description: _description
            });
            emit UpdateWorld(_world, _name, _icon, _url, _description);
        }
    }

    function setAdmin(address _addr) public onlyOwner {
        require(_addr != address(0), "Metaverse: zero address");
        _admin = _addr;
        emit SetAdmin(_addr);
    }

    function getOrCreateAccountId(address _address)
        public
        returns (uint256 id)
    {
        if (_addressesToIds[_address] == 0 && _address != address(0)) {
            id = createAccount(_address, false);
        } else {
            id = _addressesToIds[_address];
        }
    }

    function createAccount(address _address, bool _isTrustAdmin)
        public
        returns (uint256 id)
    {
        require(_address != address(0), "Metaverse: zero address");
        require(_addressesToIds[_address] == 0, "Metaverse: address is exist");
        _totalAccount++;
        id = _totalAccount;
        _accountsById[id] = Account(true, _isTrustAdmin, false, id, _address);
        _addressesToIds[_address] = id;
        emit CreateAccount(id, _address);
    }

    function changeAccount(
        uint256 _id,
        address _newAddress,
        bool _isTrustAdmin
    ) public {
        require(_newAddress != address(0), "Metaverse: zero address");
        require(
            _addressesToIds[_newAddress] == 0,
            "Metaverse: address is exist"
        );
        Account storage account = _accountsById[_id];
        require(account._isExist == true, "World: account is not exist");
        require(
            msg.sender == account._address ||
                ((account._isTrustAdmin || account._isFreeze) &&
                    msg.sender == _admin),
            "Metaverse: sender not owner or admin"
        );

        if (account._address != _newAddress) {
            delete _addressesToIds[account._address];
            _addressesToIds[_newAddress] = _id;
            account._address = _newAddress;
        }
        account._isTrustAdmin = _isTrustAdmin;
        emit UpdateAccount(_id, _newAddress, _isTrustAdmin);
    }

    function changeAccountBWO(
        uint256 _id,
        address _newAddress,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(isBWO(msg.sender),"Metaverse: sender is not BWO");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 id,address new,bool isTrustAdmin,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _id,
                        _newAddress,
                        _isTrustAdmin,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        changeAccount(_id, _newAddress, _isTrustAdmin);
    }

    function freezeAccount(uint256 _id) public {
        require(
            _accountsById[_id]._isExist == true,
            "Metaverse: account is not exist"
        );
        require(
            _accountsById[_id]._address == msg.sender,
            "Metaverse: sender not owner"
        );

        _accountsById[_id]._isFreeze = true;
        emit FreezeAccount(_id);
    }

    function freezeAccountBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(isBWO(msg.sender),"Metaverse: sender is not BWO");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 id,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _id,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        freezeAccount(_id);
    }

    function unfreezeAccount(uint256 _id) public {
        require(msg.sender == _admin, "Metaverse: sender is not admin");
        _accountsById[_id]._isFreeze = false;
        emit UnFreezeAccount(_id);
    }

    function unfreezeAccountBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(isBWO(msg.sender),"Metaverse: sender is not BWO");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 id,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _id,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        unfreezeAccount(_id);
    }

    function addOperator(address _operator) public onlyOwner {
        require(_operator != address(0), "Metaverse: zero address");
        _isOperatorByAddress[_operator] = true;
        emit AddOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner {
        delete _isOperatorByAddress[_operator];
        emit RemoveOperator(_operator);
    }

    function isOperator(address _operator) public view returns (bool) {
        return _isOperatorByAddress[_operator];
    }

    function isBWO(address _addr) public view returns (bool) {
        return _isOperatorByAddress[_addr] || _owner == _addr;
    }

    function checkAddress(address _address, uint256 _id)
        public
        view
        returns (bool)
    {
        return _accountsById[_id]._address == _address;
    }

    function getIdByAddress(address _address) public view returns (uint256) {
        return _addressesToIds[_address];
    }

    function getAddressById(uint256 _id) public view returns (address) {
        return _accountsById[_id]._address;
    }

    function isFreeze(uint256 _id) public view returns (bool) {
        return _accountsById[_id]._isFreeze;
    }

    function getAccountInfo(uint256 _id) public view returns (Account memory) {
        return _accountsById[_id];
    }

    function getAdmin() public view returns (address) {
        return _admin;
    }

    function getTotalAccount() public view returns (uint256) {
        return _totalAccount;
    }

    function getWorldInfo(address _world)
        public
        view
        returns (WorldInfo memory)
    {
        return worldInfos[_world];
    }

    function containsWorld(address _world) public view returns (bool) {
        return worlds.contains(_world);
    }

    function getWorlds() public view returns (address[] memory) {
        return worlds.values();
    }

    function getWorldCount() public view returns (uint256) {
        return worlds.length();
    }

    function getNonce(address account) public view returns (uint256) {
        return _nonces[account];
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "Metaverse: BWO call expired");
        require(
            signer == ECDSA.recover(digest, signature),
            "Metaverse: recoverSig failed"
        );
    }
}
