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
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract World is IWorld, Ownable, Initializable, EIP712 {
    // event 注册Asset
    event RegisterAsset(
        address indexed asset,
        string name,
        string image,
        IWorldAsset.ProtocolEnum protocol
    );

    event UpdateAsset(address indexed asset, string image);
    event DisableAsset(address indexed asset);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event AddSafeContract(address indexed safeContract, string name);
    event RemoveSafeContract(address indexed safeContract);
    event TrustContract(uint256 indexed id, address indexed safeContract);
    event UntrustContract(uint256 indexed id, address indexed safeContract);
    event TrustWorld(uint256 indexed id);
    event UntrustWorld(uint256 indexed id);
    event TrustContractBWO(
        uint256 indexed id,
        address indexed safeContract,
        address indexed sender,
        uint256 nonce
    );
    event UntrustContractBWO(
        uint256 indexed id,
        address indexed safeContract,
        address indexed sender,
        uint256 nonce
    );

    event TrustWorldBWO(
        uint256 indexed id,
        address indexed sender,
        uint256 nonce
    );
    event UntrustWorldBWO(
        uint256 indexed id,
        address indexed sender,
        uint256 nonce
    );
    // struct Asset
    struct Asset {
        bool _isExist;
        bool _isEnabled;
        address _contract;
        string _name;
        string _image;
        IWorldAsset.ProtocolEnum _protocol;
    }

    // struct Contract
    struct Contract {
        bool _isExist;
        address _contract;
        string _name;
    }

    // Mapping from address to operator
    mapping(address => bool) private _isOperatorByAddress;

    // Mapping from address to trust contract
    mapping(address => Contract) private _safeContracts;

    // Mapping from account Id to contract
    mapping(uint256 => mapping(address => bool))
        private _isTrustContractByAccountId;

    mapping(uint256 => bool) private _isTrustWorld;

    // Mapping from address to Asset
    mapping(address => Asset) private _assets;

    // nonce
    mapping(address => uint256) private _nonces;

    address[] private _assetAddresses;

    address private _metaverse;

    // constructor
    constructor(
        address metaverse,
        string memory name_,
        string memory version_
    ) EIP712(name_, version_) {
        _owner = msg.sender;
        _metaverse = metaverse;
    }

    modifier onlyAsset() {
        require(
            _assets[msg.sender]._isExist && _assets[msg.sender]._isEnabled,
            "World: asset is not exist or disabled"
        );
        _;
    }

    function registerAsset(address _contract, string calldata _image)
        public
        onlyOwner
    {
        require(_contract != address(0), "World: zero address");
        require(_assets[_contract]._isExist == false, "World: asset is exist");
        require(
            address(this) == IWorldAsset(_contract).worldAddress(),
            "World: world address is not match"
        );

        string memory symbol = IWorldAsset(_contract).symbol();
        IWorldAsset.ProtocolEnum _protocol = IWorldAsset(_contract).protocol();
        _assets[_contract] = Asset(
            true,
            true,
            _contract,
            symbol,
            _image,
            _protocol
        );
        _assetAddresses.push(_contract);
        emit RegisterAsset(_contract, symbol, _image, _protocol);
    }

    function updateAsset(address _contract, string calldata _image)
        public
        onlyOwner
    {
        require(
            _assets[_contract]._isExist == true,
            "World: asset is not exist"
        );

        _assets[_contract]._image = _image;
        emit UpdateAsset(_contract, _image);
    }

    function disableAsset(address _contract) public onlyOwner {
        require(
            _assets[_contract]._isExist == true,
            "World: asset is not exist"
        );

        _assets[_contract]._isEnabled = false;
        emit DisableAsset(_contract);
    }

    function getAsset(address _contract) public view returns (Asset memory) {
        return _assets[_contract];
    }

    function addSafeContract(address _contract, string calldata _name)
        public
        onlyOwner
    {
        require(_contract != address(0), "World: zero address");
        _safeContracts[_contract] = Contract(true, _contract, _name);
        emit AddSafeContract(_contract, _name);
    }

    function removeSafeContract(address _contract) public onlyOwner {
        _safeContracts[_contract]._isExist == false;
        emit RemoveSafeContract(_contract);
    }

    function isSafeContract(address _contract) public view returns (bool) {
        return _safeContracts[_contract]._isExist;
    }

    function getSafeContract(address _contract)
        public
        view
        returns (Contract memory)
    {
        return _safeContracts[_contract];
    }

    function addOperator(address _operator) public onlyOwner {
        require(_operator != address(0), "World: zero address");
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

    function isBWO(address _addr) public view virtual override returns (bool) {
        return _isOperatorByAddress[_addr] || _owner == _addr;
    }

    function isBWOByAsset(address _addr)
        public
        view
        virtual
        override
        onlyAsset
        returns (bool)
    {
        return isBWO(_addr);
    }

    function trustContract(address _contract) public returns (uint256) {
        return _trustContract(msg.sender, _contract);
    }

    function trustContractBWO(
        address _contract,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public returns (uint256) {
        require(isBWO(msg.sender), "World: sender is not BWO");
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(address contract,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _contract,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        uint256 accountId = _trustContract(sender, _contract);
        emit TrustContractBWO(accountId, _contract, sender, nonce);
        _nonces[sender]++;
        return accountId;
    }

    function _trustContract(address _address, address _contract)
        private
        returns (uint256 accountId)
    {
        accountId = getOrCreateAccountId(_address);
        _isTrustContractByAccountId[accountId][_contract] = true;
        emit TrustContract(accountId, _contract);
    }

    function untrustContract(uint256 _id, address _contract) public {
        require(
            getAddressById(_id) == msg.sender,
            "World: sender not account owner"
        );
        _untrustContract(_id, _contract);
    }

    function untrustContractBWO(
        uint256 _id,
        address _contract,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(isBWO(msg.sender), "World: sender is not BWO");
        require(
            getAddressById(_id) == sender,
            "World: sender not account owner"
        );
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 id,address contract,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _id,
                        _contract,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        _untrustContract(_id, _contract);
        emit UntrustContractBWO(_id, _contract, sender, nonce);
        _nonces[sender]++;
    }

    function _untrustContract(uint256 _id, address _contract) private {
        delete _isTrustContractByAccountId[_id][_contract];
        emit UntrustContract(_id, _contract);
    }

    function trustWorld() public returns (uint256) {
        return _trustWorld(msg.sender);
    }

    function trustWorldBWO(
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public returns (uint256) {
        require(isBWO(msg.sender), "World: sender is not BWO");

        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(address sender,uint256 nonce,uint256 deadline)"
                        ),
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        uint256 accountId = _trustWorld(sender);
        emit TrustWorldBWO(accountId, sender, nonce);
        _nonces[sender]++;
        return accountId;
    }

    function _trustWorld(address _address) private returns (uint256) {
        uint256 accountId = getOrCreateAccountId(_address);

        _isTrustWorld[accountId] = true;
        emit TrustWorld(accountId);
        return accountId;
    }

    function untrustWorld(uint256 _id) public {
        require(
            getAddressById(_id) == msg.sender,
            "World: sender not account owner"
        );
        _untrustWorld(_id);
    }

    function untrustWorldBWO(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(isBWO(msg.sender), "World: sender is not BWO");
        require(
            getAddressById(_id) == sender,
            "World: sender not account owner"
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
        _untrustWorld(_id);
        emit UntrustWorldBWO(_id, sender, nonce);
        _nonces[sender]++;
    }

    function _untrustWorld(uint256 _id) private {
        delete _isTrustWorld[_id];
        emit UntrustWorld(_id);
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
        return
            (_safeContracts[_contract]._isExist && _isTrustWorld[_id]) ||
            _isTrustContractByAccountId[_id][_contract];
    }

    function isTrustContract(address _contract, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrust)
    {
        return _isTrustContractByAccountId[_id][_contract];
    }

    function isTrustByAsset(address _contract, uint256 _id)
        public
        view
        virtual
        override
        onlyAsset
        returns (bool _isTrust)
    {
        return isTrust(_contract, _id);
    }

    function getMetaverse() public view override returns (address) {
        return _metaverse;
    }

    function checkAddress(address _address, uint256 _id)
        public
        view
        override
        returns (bool)
    {
        return Metaverse(_metaverse).checkAddressByWorld(_address, _id);
    }

    function getAccountIdByAddress(address _address)
        public
        view
        override
        returns (uint256)
    {
        return Metaverse(_metaverse).getIdByAddressByWorld(_address);
    }

    function getAddressById(uint256 _id)
        public
        view
        override
        returns (address)
    {
        return Metaverse(_metaverse).getAddressByIdByWorld(_id);
    }

    function isFreeze(uint256 _id) public view override returns (bool) {
        return Metaverse(_metaverse).isFreezeByWorld(_id);
    }

    function getOrCreateAccountId(address _address)
        public
        override
        returns (uint256 id)
    {
        return Metaverse(_metaverse).getOrCreateAccountIdByWorld(_address);
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
        require(block.timestamp < deadline, "World: BWO call expired");
        require(
            signer == ECDSA.recover(digest, signature),
            "World: recoverSig failed"
        );
    }
}
