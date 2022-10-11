//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IMetaverse.sol";
import "../interfaces/IApplyStorage.sol";
import "../interfaces/IAsset721.sol";
import "../interfaces/IAsset20.sol";
import "../interfaces/IAsset.sol";
import "../storage/WorldStorage.sol";
import "../common/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract MonsterGalaxy is IWorld, IApplyStorage, Ownable, EIP712 {
    event RegisterAsset(address indexed asset, IAsset.ProtocolEnum protocol);
    event DisableAsset(address indexed asset);
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);
    event AddSafeContract(address indexed safeContract, string name);
    event RemoveSafeContract(address indexed safeContract);
    event TrustWorld(uint256 indexed accountId, bool isTrustWorld, bool isBWO, address indexed Sender, uint256 nonce);
    event TrustContract(
        uint256 indexed accountId,
        address indexed Contract,
        bool isTrustWorld,
        bool isBWO,
        address indexed Sender,
        uint256 nonce
    );

    string public name;
    IMetaverse public metaverse;
    WorldStorage public worldStorage;
    mapping(address => bool) public isOperator;

    constructor(
        address metaverse_,
        address worldStorage_,
        string memory name_,
        string memory version_
    ) EIP712(name_, version_) {
        metaverse = IMetaverse(metaverse_);
        _owner = msg.sender;
        name = name_;
        worldStorage = WorldStorage(worldStorage_);
    }

    modifier onlyAsset() {
        WorldStorage.Asset memory asset = worldStorage.getAsset(msg.sender);
        require(asset.isExist && asset.isEnabled, "World: asset is not exist or disabled");
        _;
    }

    /**
     * @dev See {IApplyStorage-getStorageAddress}.
     */
    function getStorageAddress() external view returns (address) {
        return address(worldStorage);
    }

    function setName(string name_) public onlyOwner {
        name = name_;
    }

    function registerAsset(address _address) public onlyOwner {
        require(_address != address(0), "World: zero address");
        require(address(this) == IAsset(_address).worldAddress(), "World: world address is not match");
        require(worldStorage.getAsset(_address).isExist == false, "World: asset is exist");

        worldStorage.setAsset(_address);
        emit RegisterAsset(_address, IAsset(_address).protocol());
    }

    function disableAsset(address _address) public onlyOwner {
        worldStorage.updateAsset(_address, false);
        emit DisableAsset(_address);
    }

    function getAsset(address _address) public view returns (WorldStorage.Asset memory) {
        return worldStorage.getAsset(_address);
    }

    function addSafeContract(address _address, string calldata _name) public onlyOwner {
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

    function getSafeContract(address _address) public view returns (WorldStorage.Contract memory) {
        return worldStorage.getSafeContract(_address);
    }

    function addOperator(address _address) public onlyOwner {
        require(_address != address(0), "World: zero address");
        isOperator[_address] = true;
        emit AddOperator(_address);
    }

    function removeOperator(address _address) public onlyOwner {
        delete isOperator[_address];
        emit RemoveOperator(_address);
    }

    function trustContract(
        uint256 _id,
        address _address,
        bool _isTrustContract
    ) public {
        metaverse.checkSender(_id, msg.sender);
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
        metaverse.checkSender(_id, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 id,address contract,bool flag,address sender,uint256 nonce,uint256 deadline)"
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
        worldStorage.setTrustContractByAccountId(_id, _address, _isTrustContract);
        emit TrustContract(_id, _address, _isTrustContract, _isBWO, _sender, getNonce(_sender));
        worldStorage.IncrementNonce(_sender);
    }

    function trustWorld(uint256 _id, bool _isTrustWorld) public {
        metaverse.checkSender(_id, msg.sender);
        _trustWorld(_id, _isTrustWorld, false, msg.sender);
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
        metaverse.checkSender(_id, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("BWO(uint256 id,bool flag,address sender,uint256 nonce,uint256 deadline)"),
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
        emit TrustWorld(_id, _isTrustWorld, _isBWO, _sender, getNonce(_sender));
        worldStorage.IncrementNonce(_sender);
    }

    /**
     * @dev See {IWorld-isTrustWorld}.
     */
    function isTrustWorld(uint256 _id) public view virtual override returns (bool _isTrustWorld) {
        return worldStorage.isTrustWorld(_id);
    }

    /**
     * @dev See {IWorld-isTrust}.
     */
    function isTrust(address _contract, uint256 _id) public view virtual override returns (bool _isTrust) {
        return (isSafeContract(_contract) && isTrustWorld(_id)) || isTrustContract(_contract, _id);
    }

    /**
     * @dev See {IWorld-isTrustContract}.
     */
    function isTrustContract(address _contract, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrustContract)
    {
        return worldStorage.isTrustContractByAccountId(_id, _contract);
    }

    /**
     * @dev See {IWorld-isBWOByAsset}.
     */
    function checkBWOByAsset(address _address) public view virtual override onlyAsset returns (bool) {
        return checkBWO(_address);
    }

    /**
     * @dev See {IWorld-isTrustByAsset}.
     */
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

    /**
     * @dev See {IWorld-getMetaverse}.
     */
    function getMetaverse() public view override returns (address) {
        return address(metaverse);
    }

    function checkBWO(address _address) public view returns (bool) {
        return isOperator[_address] || _owner == _address;
    }

    function getNonce(address _address) public view returns (uint256) {
        return worldStorage.nonces(_address);
    }

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
        require(signer == ECDSA.recover(digest, signature), "World: recoverSig failed");
    }
}
