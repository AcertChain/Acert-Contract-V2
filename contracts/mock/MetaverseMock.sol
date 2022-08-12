//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../common/Ownable.sol";
import "./WorldMock.sol";
import "../storage/MetaverseStorage.sol";
import "../proxy/AuthProxy.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract MetaverseMock is Ownable, EIP712 {
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
        address indexed authAddress,
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
    event addAuthProxy(uint256 indexed id, address indexed proxy);
    event addAuthProxyBWO(
        uint256 indexed id,
        address indexed addr,
        address indexed sender,
        uint256 nonce
    );
    event removeAuthProxy(uint256 indexed id, address indexed proxy);
    event removeAuthProxyBWO(
        uint256 indexed id,
        address indexed addr,
        address indexed sender,
        uint256 nonce
    );

    address public _admin;
    uint256 public immutable _startId;
    MetaverseStorage public metaStorage;
    // Mapping from address to operator
    mapping(address => bool) public isOperator;

    constructor(
        string memory name_,
        string memory version_,
        uint256 startId_,
        address metaStorage_
    ) EIP712(name_, version_) {
        _owner = msg.sender;
        _startId = startId_;
        metaStorage = MetaverseStorage(metaStorage_);
    }

    function registerWorld(
        address _world,
        string calldata _name,
        string calldata _icon,
        string calldata _url,
        string calldata _description
    ) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        require(
            metaStorage.contains(_world) == false,
            "Metaverse: world is exist"
        );
        require(
            World(_world).getMetaverse() == address(this),
            "Metaverse: metaverse is not match"
        );
        metaStorage.add(_world);
        metaStorage.addWorldInfo(
            MetaverseStorage.WorldInfo({
                world: _world,
                name: _name,
                icon: _icon,
                url: _url,
                description: _description,
                isEnabled: true
            })
        );
        emit RegisterWorld(_world, _name, _icon, _url, _description);
    }

    function disableWorld(address _world) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        metaStorage.disableWorld(_world);
        emit DisableWorld(_world);
    }

    function updateWorldInfo(
        address _world,
        string calldata _name,
        string calldata _icon,
        string calldata _url,
        string calldata _description
    ) public onlyOwner {
        require(_world != address(0), "Metaverse: zero address");
        if (metaStorage.contains(_world)) {
            MetaverseStorage.WorldInfo memory info = getWorldInfo(_world);
            info.name = _name;
            info.icon = _icon;
            info.url = _url;
            info.description = _description;
            metaStorage.addWorldInfo(info);
        }
        emit UpdateWorld(_world, _name, _icon, _url, _description);
    }

    function getWorldInfo(address _world)
        public
        view
        returns (MetaverseStorage.WorldInfo memory)
    {
        return metaStorage.getWorldInfo(_world);
    }

    function containsWorld(address _world) public view returns (bool) {
        return metaStorage.contains(_world);
    }

    function getWorlds() public view returns (address[] memory) {
        return metaStorage.values();
    }

    function getWorldCount() public view returns (uint256) {
        return metaStorage.length();
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
        isOperator[_operator] = true;
        emit AddOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner {
        delete isOperator[_operator];
        emit RemoveOperator(_operator);
    }

    function isBWO(address _addr) public view returns (bool) {
        return isOperator[_addr] || _owner == _addr;
    }

    function getOrCreateAccountId(address _address)
        public
        returns (uint256 id)
    {
        if (_address != address(0) && getIdByAddress(_address) == 0) {
            id = createAccount(_address, false);
        } else {
            id = getIdByAddress(_address);
        }
    }

    function createAccount(address _address, bool _isTrustAdmin)
        public
        virtual
        returns (uint256 id)
    {
        metaStorage.IncrementTotalAccount();
        id = metaStorage.totalAccount() + _startId;
        _createAccount(id, _address, _isTrustAdmin);
    }

    function _createAccount(
        uint256 _id,
        address _address,
        bool _isTrustAdmin
    ) internal virtual {
        require(_address != address(0), "Metaverse: zero address");
        require(getIdByAddress(_address) == 0, "Metaverse: address is exist");

        AuthProxy authProxy = new AuthProxy(
            "auth",
            "v1.0",
            address(metaStorage)
        );

        authProxy.addAddr(_address);
        emit addAuthProxy(_id, _address);

        metaStorage.addAccount(
            MetaverseStorage.Account(
                true,
                _isTrustAdmin,
                false,
                _id,
                _address,
                address(authProxy)
            )
        );
        metaStorage.addAddressToId(_address, _id);
        emit CreateAccount(_id, _address, _isTrustAdmin);
    }

    function changeAccount(
        uint256 _id,
        address _newAddress,
        bool _isTrustAdmin
    ) public {
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isExist == true, "Metaverse: account is not exist");
        require(
            msg.sender == account.addr ||
                (msg.sender == _admin &&
                    (account.isTrustAdmin || account.isFreeze)),
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
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isExist == true, "Metaverse: account is not exist");
        require(account.addr == sender, "Metaverse: sender not owner");
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
        metaStorage.IncrementNonce(sender);
    }

    function _changeAccount(
        uint256 _id,
        address _newAddress,
        bool _isTrustAdmin
    ) private {
        require(_newAddress != address(0), "Metaverse: zero address");
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isExist == true, "Metaverse: account is not exist");

        if (account.addr != _newAddress) {
            require(
                getIdByAddress(_newAddress) == 0,
                "Metaverse: new address has been used"
            );
            metaStorage.deleteAddressToId(account.addr);
            metaStorage.addAddressToId(_newAddress, _id);
            AuthProxy(account.proxy).addAddr(_newAddress);
            emit addAuthProxy(account.id, _newAddress);
            AuthProxy(account.proxy).removeAddr(account.addr);
            emit removeAuthProxy(account.id, account.addr);
            account.addr = _newAddress;
        }
        account.isTrustAdmin = _isTrustAdmin;
        metaStorage.addAccount(account);
        emit UpdateAccount(_id, _newAddress, _isTrustAdmin);
    }

    function freezeAccount(uint256 _id) public {
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isExist == true, "Metaverse: account is not exist");
        require(account.addr == msg.sender, "Metaverse: sender not owner");
        account.isFreeze = true;
        metaStorage.addAccount(account);
        emit FreezeAccount(_id);
    }

    function freezeAccountBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(isBWO(msg.sender), "Metaverse: sender is not BWO");
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        require(account.isExist == true, "Metaverse: account is not exist");
        require(account.addr == sender, "Metaverse: sender not owner");
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

        account.isFreeze = true;
        metaStorage.addAccount(account);
        emit FreezeAccount(_id);
        emit FreezeAccountBWO(_id, nonce);
        metaStorage.IncrementNonce(sender);
    }

    function unfreezeAccount(uint256 _id) public {
        require(msg.sender == _admin, "Metaverse: sender is not admin");
        MetaverseStorage.Account memory account = getAccountInfo(_id);
        account.isFreeze = false;
        emit UnFreezeAccount(_id);
    }

    function addAuthProxyAddr(
        uint256 id,
        address addr,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        MetaverseStorage.Account memory account = getAccountInfo(id);
        require(account.isExist == true, "Metaverse: account is not exist");
        AuthProxy authProxy = AuthProxy(account.proxy);
        authProxy.addAddrBWO(addr, sender, deadline, signature);
        emit addAuthProxy(id, addr);
        emit addAuthProxyBWO(id, addr, sender, metaStorage.nonces(sender));
    }

    function removeAuthProxyAddr(
        uint256 id,
        address addr,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        MetaverseStorage.Account memory account = getAccountInfo(id);
        require(account.isExist == true, "Metaverse: account is not exist");
        AuthProxy authProxy = AuthProxy(account.proxy);
        authProxy.removeAddrBWO(addr, sender, deadline, signature);
        emit removeAuthProxy(id, addr);
        emit removeAuthProxyBWO(id, addr, sender, metaStorage.nonces(sender));
    }

    function addAuthProxyAddr(uint256 id, address addr) public {
        require(isBWO(msg.sender), "Metaverse: sender is not BWO");
        MetaverseStorage.Account memory account = getAccountInfo(id);
        require(account.isExist == true, "Metaverse: account is not exist");
        AuthProxy authProxy = AuthProxy(account.proxy);
        authProxy.addAddr(addr);
        emit addAuthProxy(id, addr);
    }

    function removeAuthProxyAddr(uint256 id, address addr) public {
        MetaverseStorage.Account memory account = getAccountInfo(id);
        require(account.isExist == true, "Metaverse: account is not exist");
        AuthProxy authProxy = AuthProxy(account.proxy);
        authProxy.removeAddr(addr);
        emit removeAuthProxy(id, addr);
    }

    function isFreeze(uint256 _id) public view returns (bool) {
        return getAccountInfo(_id).isFreeze;
    }

    function checkAddress(
        address _address,
        uint256 _id,
        bool _isProxy
    ) public view returns (bool) {
        if (_isProxy) {
            return AuthProxy(getAccountInfo(_id).proxy).authAddresses(_address);
        } else {
            return getAddressById(_id) == _address;
        }
    }

    function getIdByAddress(address _address) public view returns (uint256) {
        return metaStorage.addressToId(_address);
    }

    function getAddressById(uint256 _id) public view returns (address) {
        return getAccountInfo(_id).addr;
    }

    function getAccountInfo(uint256 _id)
        public
        view
        returns (MetaverseStorage.Account memory account)
    {
        return metaStorage.getAccount(_id);
    }

    function getTotalAccount() public view returns (uint256) {
        return metaStorage.totalAccount();
    }

    function getNonce(address account) public view returns (uint256) {
        return metaStorage.nonces(account);
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
