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
        uint256 nonce,
        uint256 deadline
    );
    event UntrustContractBWO(
        uint256 indexed id,
        address indexed safeContract,
        address indexed sender,
        uint256 nonce,
        uint256 deadline
    );

    event TrustWorldBWO(
        uint256 indexed id,
        address indexed sender,
        uint256 nonce,
        uint256 deadline
    );
    event UntrustWorldBWO(
        uint256 indexed id,
        address indexed sender,
        uint256 nonce,
        uint256 deadline
    );
    // struct Asset
    struct Asset {
        bool _isExist;
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
        _assets[_contract] = Asset(true, _contract, symbol, _image, _protocol);
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

    function getSafeContract(address _contract) public view returns (Contract memory) {
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

    function trustContract(uint256 _id, address _contract) public {
        require(
            getAddressById(_id) == msg.sender,
            "World: sender not account owner"
        );
        _trustContract(_id, _contract);
    }

    function trustContractBWO(
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

        _trustContract(_id, _contract);
        emit TrustContractBWO(_id, _contract, sender, nonce, deadline);
        _nonces[sender]++;
    }

    function _trustContract(uint256 _id, address _contract) private {
        require(
            _safeContracts[_contract]._isExist == true,
            "World: contract is not safe"
        );
        _isTrustContractByAccountId[_id][_contract] = true;
        emit TrustContract(_id, _contract);
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
        emit UntrustContractBWO(_id, _contract, sender, nonce, deadline);
        _nonces[sender]++;
    }

    function _untrustContract(uint256 _id, address _contract) private {
        delete _isTrustContractByAccountId[_id][_contract];
        emit UntrustContract(_id, _contract);
    }

    function trustWorld(uint256 _id) public {
        require(
            getAddressById(_id) == msg.sender,
            "World: sender not account owner"
        );
        _trustWorld(_id);
    }

    function trustWorldBWO(
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
        _trustWorld(_id);
        emit TrustWorldBWO(_id, sender, nonce, deadline);
        _nonces[sender]++;
    }

    function _trustWorld(uint256 _id) private {
        _isTrustWorld[_id] = true;
        emit TrustWorld(_id);
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
        emit UntrustWorldBWO(_id, sender, nonce, deadline);
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
            _safeContracts[_contract]._isExist &&
            (_isTrustContractByAccountId[_id][_contract] || _isTrustWorld[_id]);
    }

    function getMetaverse() public view returns (address) {
        return _metaverse;
    }

    function checkAddress(address _address, uint256 _id)
        public
        view
        override
        returns (bool)
    {
        return Metaverse(_metaverse).checkAddress(_address, _id);
    }

    function getAccountIdByAddress(address _address)
        public
        view
        override
        returns (uint256)
    {
        return Metaverse(_metaverse).getIdByAddress(_address);
    }

    function getAddressById(uint256 _id)
        public
        view
        override
        returns (address)
    {
        return Metaverse(_metaverse).getAddressById(_id);
    }

    function isFreeze(uint256 _id) public view override returns (bool) {
        return Metaverse(_metaverse).isFreeze(_id);
    }

    function getOrCreateAccountId(address _address)
        public
        override
        returns (uint256 id)
    {
        return Metaverse(_metaverse).getOrCreateAccountId(_address);
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
