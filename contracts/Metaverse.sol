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

    event RegisterWorld(
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
    event DisableWorld(address indexed world);
    event SetAdmin(address indexed admin);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event CreateAccount(
        uint256 indexed id,
        address indexed account,
        bool isTrustAdmin
    );
    event UpdateAccount(
        uint256 indexed id,
        address indexed newAddress,
        bool isTrustAdmin
    );
    event UpdateAccountBWO(
        uint256 indexed id,
        address indexed newAddress,
        bool isTrustAdmin,
        uint256 nonce
    );
    event FreezeAccount(uint256 indexed id);
    event FreezeAccountBWO(uint256 indexed id, uint256 nonce);
    event UnFreezeAccount(uint256 indexed id);

    mapping(address => WorldInfo) private worldInfos;

    struct WorldInfo {
        address world;
        string name;
        string icon;
        string url;
        string description;
        bool isEnabled;
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

    uint256 private immutable _startId;

    constructor(
        string memory name_,
        string memory version_,
        uint256 startId_
    ) EIP712(name_, version_) {
        _owner = msg.sender;
        _startId = startId_;
    }

    modifier onlyWorld() {
        require(
            worlds.contains(msg.sender),
            "Metaverse: Only world can call this function"
        );
        require(worldInfos[msg.sender].isEnabled, "Metaverse: World is disabled");
        _;
    }

    function registerWorld(
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
            description: _description,
            isEnabled: true
        });
        emit RegisterWorld(_world, _name, _icon, _url, _description);
    }

    function disableWorld(address _world) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        if (worlds.contains(_world)) {
            worldInfos[_world].isEnabled = false;
            emit DisableWorld(_world);
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
            worldInfos[_world].name = _name;
            worldInfos[_world].icon = _icon;
            worldInfos[_world].url = _url;
            worldInfos[_world].description = _description;
            emit UpdateWorld(_world, _name, _icon, _url, _description);
        }
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

    function setAdmin(address _addr) public onlyOwner {
        require(_addr != address(0), "Metaverse: zero address");
        _admin = _addr;
        emit SetAdmin(_addr);
    }

    function getAdmin() public view returns (address) {
        return _admin;
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

    function getOrCreateAccountIdByWorld(address _address)
        public
        onlyWorld
        returns (uint256 id)
    {
        return getOrCreateAccountId(_address);
    }

    function createAccount(address _address, bool _isTrustAdmin)
        public
        virtual
        returns (uint256 id)
    {
        _totalAccount++;
        id = _totalAccount + _startId;
        _createAccount(id, _address, _isTrustAdmin);
    }

    function _createAccount(
        uint256 _id,
        address _address,
        bool _isTrustAdmin
    ) internal virtual {
        require(_address != address(0), "Metaverse: zero address");
        require(_addressesToIds[_address] == 0, "Metaverse: address is exist");
        _accountsById[_id] = Account(true, _isTrustAdmin, false, _id, _address);
        _addressesToIds[_address] = _id;
        emit CreateAccount(_id, _address, _isTrustAdmin);
    }

    function changeAccount(
        uint256 _id,
        address _newAddress,
        bool _isTrustAdmin
    ) public {
        Account storage account = _accountsById[_id];
        require(
            _accountsById[_id]._isExist == true,
            "Metaverse: account is not exist"
        );
        require(
            msg.sender == account._address ||
                (msg.sender == _admin &&
                    (account._isTrustAdmin || account._isFreeze)),
            "Metaverse: sender not owner or admin"
        );
        _changeAccount(_id, _newAddress, _isTrustAdmin);
    }

    function changeAccountBWO(
        uint256 _id,
        address _newAddress,
        bool _isTrustAdmin,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(isBWO(msg.sender), "Metaverse: sender is not BWO");
        require(
            _accountsById[_id]._isExist == true,
            "Metaverse: account is not exist"
        );
        require(
            _accountsById[_id]._address == sender,
            "Metaverse: sender not owner"
        );
        uint256 nonce = getNonce(sender);
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
        _changeAccount(_id, _newAddress, _isTrustAdmin);
        emit UpdateAccountBWO(_id, _newAddress, _isTrustAdmin, nonce);
        _nonces[sender]++;
    }

    function _changeAccount(
        uint256 _id,
        address _newAddress,
        bool _isTrustAdmin
    ) private {
        require(_newAddress != address(0), "Metaverse: zero address");
        Account storage account = _accountsById[_id];
        require(account._isExist == true, "Metaverse: account is not exist");

        if (account._address != _newAddress) {
            require(
                _addressesToIds[_newAddress] == 0,
                "Metaverse: new address has been used"
            );
            delete _addressesToIds[account._address];
            _addressesToIds[_newAddress] = _id;
            account._address = _newAddress;
        }
        account._isTrustAdmin = _isTrustAdmin;
        emit UpdateAccount(_id, _newAddress, _isTrustAdmin);
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
        require(isBWO(msg.sender), "Metaverse: sender is not BWO");
        require(
            _accountsById[_id]._isExist == true,
            "Metaverse: account is not exist"
        );
        require(
            _accountsById[_id]._address == sender,
            "Metaverse: sender not owner"
        );
        uint256 nonce = getNonce(sender);
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

        _accountsById[_id]._isFreeze = true;
        emit FreezeAccount(_id);
        emit FreezeAccountBWO(_id, nonce);
        _nonces[sender]++;
    }

    function unfreezeAccount(uint256 _id) public {
        require(msg.sender == _admin, "Metaverse: sender is not admin");
        _accountsById[_id]._isFreeze = false;
        emit UnFreezeAccount(_id);
    }

    function isFreeze(uint256 _id) public view returns (bool) {
        return _accountsById[_id]._isFreeze;
    }


    function isFreezeByWorld(uint256 _id) public view onlyWorld returns (bool) {
        return isFreeze(_id);
    }

    function checkAddress(address _address, uint256 _id)
        public
        view
        returns (bool)
    {
        return _accountsById[_id]._address == _address;
    }

    function checkAddressByWorld(address _address, uint256 _id)
        public
        view
        onlyWorld
        returns (bool)
    {
        return checkAddress(_address, _id);
    }

    function getIdByAddress(address _address) public view returns (uint256) {
        return _addressesToIds[_address];
    }

    function getIdByAddressByWorld(address _address) public view onlyWorld returns (uint256) {
        return getIdByAddress(_address);
    }

    function getAddressById(uint256 _id) public view returns (address) {
        return _accountsById[_id]._address;
    }

    function getAddressByIdByWorld(uint256 _id)
        public
        view
        onlyWorld
        returns (address)
    {
        return getAddressById(_id);
    }

    function getAccountInfo(uint256 _id) public view returns (Account memory) {
        return _accountsById[_id];
    }

    function getTotalAccount() public view returns (uint256) {
        return _totalAccount;
    }

    function getNonce(address account) public view returns (uint256) {
        return _nonces[account];
    }

    // for test
    function getChainId() external view returns (uint256) {
        return block.chainid;
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
