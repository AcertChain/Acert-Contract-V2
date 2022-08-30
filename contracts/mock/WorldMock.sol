//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IWorldAsset.sol";
import "../interfaces/IItem721.sol";
import "../interfaces/ICash20.sol";
import "./MetaverseMock.sol";
import "../storage/WorldStorage.sol";
import "../common/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract WorldMock is IWorld, Ownable, EIP712 {
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

    // Mapping from address to operator
    mapping(address => bool) public isOperator;

    MetaverseMock public metaverse;

    WorldStorage public worldStorage;

    // constructor
    constructor(
        address metaverse_,
        address worldStorage_,
        string memory name_,
        string memory version_
    ) EIP712(name_, version_) {
        metaverse = MetaverseMock(metaverse_);
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

    function registerAsset(address _contract, string calldata _image)
        public
        onlyOwner
    {
        require(_contract != address(0), "World: zero address");
        require(
            worldStorage.getAsset(_contract).isExist == false,
            "World: asset is exist"
        );
        require(
            address(this) == IWorldAsset(_contract).worldAddress(),
            "World: world address is not match"
        );

        string memory symbol = IWorldAsset(_contract).symbol();
        IWorldAsset.ProtocolEnum protocol = IWorldAsset(_contract).protocol();

        worldStorage.addAsset(
            WorldStorage.Asset(true, true, _contract, symbol, _image, protocol)
        );

        worldStorage.addAssetAddress(_contract);
        emit RegisterAsset(_contract, symbol, _image, protocol);
    }

    function updateAsset(address _contract, string calldata _image)
        public
        onlyOwner
    {
        WorldStorage.Asset memory asset = worldStorage.getAsset(_contract);
        require(asset.isExist == true, "World: asset is not exist");

        asset.image = _image;
        worldStorage.addAsset(asset);
        emit UpdateAsset(_contract, _image);
    }

    function disableAsset(address _contract) public onlyOwner {
        WorldStorage.Asset memory asset = worldStorage.getAsset(_contract);
        require(asset.isExist == true, "World: asset is not exist");

        asset.isEnabled = false;
        worldStorage.addAsset(asset);
        emit DisableAsset(_contract);
    }

    function getAsset(address _contract)
        public
        view
        returns (WorldStorage.Asset memory)
    {
        return worldStorage.getAsset(_contract);
    }

    function addSafeContract(address _contract, string calldata _name)
        public
        onlyOwner
    {
        require(_contract != address(0), "World: zero address");
        worldStorage.addSafeContract(
            WorldStorage.Contract(true, _contract, _name)
        );
        emit AddSafeContract(_contract, _name);
    }

    function removeSafeContract(address _contract) public onlyOwner {
        WorldStorage.Contract memory safeContract = worldStorage
            .getSafeContract(_contract);
        safeContract.isExist = false;
        worldStorage.addSafeContract(safeContract);
        emit RemoveSafeContract(_contract);
    }

    function isSafeContract(address _contract) public view returns (bool) {
        return worldStorage.getSafeContract(_contract).isExist;
    }

    function getSafeContract(address _contract)
        public
        view
        returns (WorldStorage.Contract memory)
    {
        return worldStorage.getSafeContract(_contract);
    }

    function addOperator(address _operator) public onlyOwner {
        require(_operator != address(0), "World: zero address");
        isOperator[_operator] = true;
        emit AddOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner {
        delete isOperator[_operator];
        emit RemoveOperator(_operator);
    }

    function isBWO(address _addr) public view virtual override returns (bool) {
        return isOperator[_addr] || _owner == _addr;
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
        trustContractBWOParamsVerify(_contract, sender, deadline, signature);
        uint256 accountId = _trustContract(sender, _contract);
        emit TrustContractBWO(accountId, _contract, sender, getNonce(sender));
        worldStorage.IncrementNonce(sender);
        return accountId;
    }

    function trustContractBWOParamsVerify(
        address _contract,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
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
        return true;
    }

    function _trustContract(address _address, address _contract)
        private
        returns (uint256 accountId)
    {
        accountId = getOrCreateAccountId(_address);
        worldStorage.trustContractByAccountId(accountId, _contract);
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
        untrustContractBWOParamsVerify(
            _id,
            _contract,
            sender,
            deadline,
            signature
        );

        _untrustContract(_id, _contract);
        emit UntrustContractBWO(_id, _contract, sender, getNonce(sender));
        worldStorage.IncrementNonce(sender);
    }

    function untrustContractBWOParamsVerify(
        uint256 _id,
        address _contract,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
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
        return true;
    }

    function _untrustContract(uint256 _id, address _contract) private {
        worldStorage.untrustContractByAccountId(_id, _contract);
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
        trustWorldBWOParamsVerify(sender, deadline, signature);
        uint256 accountId = _trustWorld(sender);
        emit TrustWorldBWO(accountId, sender, getNonce(sender));
        worldStorage.IncrementNonce(sender);
        return accountId;
    }

    function trustWorldBWOParamsVerify(
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
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
        return true;
    }

    function _trustWorld(address _address) private returns (uint256) {
        uint256 accountId = getOrCreateAccountId(_address);

        worldStorage.trustWorld(accountId);
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
        untrustWorldBWOParamsVerify(_id, sender, deadline, signature);
        _untrustWorld(_id);
        emit UntrustWorldBWO(_id, sender, getNonce(sender));
        worldStorage.IncrementNonce(sender);
    }

    function untrustWorldBWOParamsVerify(
        uint256 _id,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
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
        return true;
    }

    function _untrustWorld(uint256 _id) private {
        worldStorage.untrustWorld(_id);
        emit UntrustWorld(_id);
    }

    function isTrustWorld(uint256 _id) public view returns (bool _isTrust) {
        return worldStorage.isTrustWorld(_id);
    }

    function isTrust(address _contract, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrust)
    {
        return
            (isSafeContract(_contract) && isTrustWorld(_id)) ||
            isTrustContract(_contract, _id);
    }

    function isTrustContract(address _contract, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrust)
    {
        return worldStorage.isTrustContractByAccountId(_id, _contract);
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
        return address(metaverse);
    }

    function checkAddress(
        address _address,
        uint256 _id,
        bool proxy
    ) public view override returns (bool) {
        return metaverse.checkAddress(_address, _id, proxy);
    }

    function getAccountIdByAddress(address _address)
        public
        view
        override
        returns (uint256)
    {
        return metaverse.getIdByAddress(_address);
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

    function getNonce(address account) public view returns (uint256) {
        return worldStorage.nonces(account);
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
