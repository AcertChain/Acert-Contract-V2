//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IWorldAsset.sol";
import "../interfaces/IItem721.sol";
import "../interfaces/ICash20.sol";
import "./MogaMetaverse.sol";
import "../storage/WorldStorage.sol";
import "../common/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract MonsterGalaxy is IWorld, Ownable, EIP712 {
    // event 注册Asset
    event RegisterAsset(
        address indexed asset,
        IWorldAsset.ProtocolEnum protocol
    );

    event DisableAsset(address indexed asset);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
 
    event AddSafeContract(address indexed safeContract, string name);
    event RemoveSafeContract(address indexed safeContract);
 
     event AddTrustContract(
        uint256 indexed accountId,
        address indexed Contract,
        bool isBWO,
        address indexed Sender,
        uint256 nonce
    );
 
     event RemoveTrustContract(
        uint256 indexed accountId,
        address indexed Contract,
        bool isBWO,
        address indexed Sender,
        uint256 nonce
    );

     event TrustWorld(
        uint256 indexed accountId,
        bool isTrustWorld,
        bool isBWO,
        address indexed Sender,
        uint256 nonce
    );

    // Mapping from address to operator
    mapping(address => bool) public isOperator;

    MogaMetaverse public metaverse;

    WorldStorage public worldStorage;

    // constructor
    constructor(
        address metaverse_,
        address worldStorage_,
        string memory name_,
        string memory version_
    ) EIP712(name_, version_) {
        metaverse = MogaMetaverse(metaverse_);
        _owner = msg.sender;
        worldStorage = WorldStorage(worldStorage_);
    }

    modifier onlyAsset() {
        WorldStorage.Asset memory asset = worldStorage.getAsset(msg.sender);
        require(
            asset.isExist && asset.isEnabled,
            "World: asset is not exist or disabled"
        );
        _;
    }

    function registerAsset(address _address)
        public
        onlyOwner
    {
        require(_address != address(0), "World: zero address");
        require(
            address(this) == IWorldAsset(_address).worldAddress(),
            "World: world address is not match"
        );
        require(
            worldStorage.getAsset(_address).isExist == false,
            "World: asset is exist"
        );

        worldStorage.setAsset(_address);
        emit RegisterAsset(_address, protocol);
    }

    function disableAsset(address _address) public onlyOwner {
        worldStorage.updateAsset(_address, false);
        emit DisableAsset(_contract);
    }

    function getAsset(address _address)
        public
        view
        returns (WorldStorage.Asset memory)
    {
        return worldStorage.getAsset(_address);
    }

    function addSafeContract(address _address, string calldata _name)
        public
        onlyOwner
    {
        require(_address != address(0), "World: zero address");
        worldStorage.addSafeContract(_address, _name);
        emit AddSafeContract(_address, _name);
    }

    function removeSafeContract(address _address) public onlyOwner {
        worldStorage.removeSafeContract(_address);
        emit RemoveSafeContract(_address);
    }

    function isSafeContract(address _address) public view returns (bool) {
        return worldStorage.getSafeContract(_address).isExist;
    }

    function getSafeContract(address _address)
        public
        view
        returns (WorldStorage.Contract memory)
    {
        return worldStorage.getSafeContract(_address);
    }

    function addOperator(address _address) public onlyOwner {
        require(_address != address(0), "World: zero address");
        isOperator[_address] = true;
        emit AddOperator(_address);
    }

    function removeOperator(address _address) public onlyOwner {
        delete _address[_operator];
        emit RemoveOperator(_address);
    }

    function checkBWO(address _address) public view virtual override returns (bool) {
        return isOperator[_addr] || _owner == _address;
    }

    function isBWOByAsset(address _address)
        public
        view
        virtual
        override
        onlyAsset
        returns (bool)
    {
        return checkBWO(_address);
    }

    function trustContract(
        uint256 _id, 
        address _address, 
        bool _isTrustContract
    ) public {
        checkSender(_id, msg.sender);
        _trustContract(_id, _address, _isTrustContract, false, msg.sender);
    }

    function trustContractBWO(
        uint256 _id,
        address _address, 
        bool _isTrustContract,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        checkBWO(msg.sender);
        trustContractBWOParamsVerify(_id, _address, _isTrustContract, sender, deadline, signature);
        _trustContract(_id, _address, _isTrustContract, true, sender);
    }

    function trustContractBWOParamsVerify(
        uint256 _id,
        address _address,
        bool _isTrustContract,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        checkSender(_id, sender);
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
                        _id,
                        _address,
                        _isTrustContract,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        return true;
    }

    function _trustContract(
        uint256 _id,
        address _address,
        bool _isTrustContract,
        bool _isBWO,
        address _sender
    ) private {
        accountId = getOrCreateAccountId(_address);
        worldStorage.setTrustContractByAccountId(_id, _address, _isTrustContract);
        emit TrustContract(_id, _address, _isTrustContract, _isBWO, _sender, getNonce(_sender));
        worldStorage.IncrementNonce(_sender);
    }

    function trustWorld(
        uint256 _id,
        bool _isTrustWorld
    ) public {
        checkSender(_id, msg.sender);
        _trustAdmin(_id, _isTrustWorld, false, msg.sender);
    }

    function trustWorldBWO(
        uint256 _id,
        bool _isTrustWorld,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public {
        checkBWO(msg.sender);
        trustWorldBWOParamsVerify(_id, _isTrustWorld, sender, deadline, signature);
        _trustWorld(_id, _isTrustWorld, true, sender);
    }

    function trustWorldBWOParamsVerify(
        uint256 _id,
        bool _isTrustWorld,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        checkSender(_id, sender);
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
                        _id,
                        _isTrustWorld,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        return true;
    }

    function _trustWorld(
        uint256 _id,
        bool _isTrustWorld,
        bool _isBWO,
        address _sender
    ) private {

        worldStorage.setTrustWorld(_id, _isTrustWorld);
        emit TrustWorld(_id, _address, _isTrustWorld, _isBWO, _sender, getNonce(_sender));
        worldStorage.IncrementNonce(_sender);
    }

    function isTrustWorld(uint256 _id) public view returns (bool _isTrust) {
        return worldStorage.isTrustWorld(_id);
    }

    function isTrust(address _address, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrust)
    {
        return
            (isSafeContract(_address) && isTrustWorld(_id)) ||
            isTrustContract(_address, _id);
    }

    function isTrustContract(address _address, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrust)
    {
        return worldStorage.isTrustContractByAccountId(_id, _address);
    }

    function isTrustByAsset(address _address, uint256 _id)
        public
        view
        virtual
        override
        onlyAsset
        returns (bool _isTrust)
    {
        return isTrust(_address, _id);
    }

    function getMetaverse() public view override returns (address) {
        return address(metaverse);
    }

    function checkSender(uint256 _id, address _sender) public {
        return metaverse.checkSender(_id, _address);
    }

    function getAccountIdByAddress(address _address)
        public
        view
        override
        returns (uint256)
    {
        return metaverse.getAccountIdByAddress(_address);
    }

    function getAddressById(uint256 _id)
        public
        view
        override
        returns (address)
    {
        return metaverse.getAddressById(_id);
    }

    function isFreeze(uint256 _id) public view override returns (bool) {
        return metaverse.isFreeze(_id);
    }

    function getOrCreateAccountId(address _address)
        public
        override
        returns (uint256 id)
    {
        return metaverse.getOrCreateAccountId(_address);
    }

    function getNonce(address _address) public view returns (uint256) {
        return worldStorage.nonces(_address);
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
