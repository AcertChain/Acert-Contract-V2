//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IWorld.sol";
import "../interfaces/IMetaverse.sol";
import "../interfaces/ShellCore.sol";
import "../interfaces/IAcertContract.sol";
import "../interfaces/IApplyStorage.sol";
import "./WorldStorage.sol";
import "./World.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorldCore is IWorld, CoreContract, IAcertContract, IApplyStorage, EIP712 {
    string public worldName;
    string public worldVersion;
    IMetaverse public metaverse;
    WorldStorage metaStorage;

    constructor(
        address metaverse_,
        address _metaStorage,
        string memory _name,
        string memory _version
    ) EIP712(_name, _version) {
        metaverse = IMetaverse(metaverse_);
        worldName = _name;
        worldVersion = versi_versionon_;
        metaStorage = WorldStorage(_metaStorage);
    }

    function shell() public view returns (World) {
        return World(shellContract);
    }

    /**
     * @dev See {IApplyStorage-getStorageAddress}.
     */
    function getStorageAddress() public view override returns (address) {
        return address(metaStorage);
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return shellContract;
    }

    //world
    /**
     * @dev See {IWorld-name}.
     */
    function name() public view override returns (string memory) {
        return worldName;
    }

    /**
     * @dev See {IWorld-version}.
     */
    function version() public view override returns (string memory) {
        return worldVersion;
    }

    /**
     * @dev See {IWorld-isTrustWorld}.
     */
    function isTrustWorld(uint256 _id) public view override returns (bool _isTrustWorld) {
        return worldStorage.isTrustWorld(_id);
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
     * @dev See {IWorld-isTrust}.
     */
    function isTrust(address _contract, uint256 _id) public view override returns (bool _isTrust) {
        return (worldStorage.isSafeContract(_contract) && isTrustWorld(_id)) || isTrustContract(_contract, _id);
    }

    //trustContract
    function trustContract(
        uint256 _id,
        address _address,
        bool _isTrustContract
    ) public override onlyShell {
        metaverse.checkSender(_id, _msgSender());
        _trustContract(_id, _address, _isTrustContract, false, _msgSender());
    }

    function trustContractBWO(
        uint256 _id,
        address _address,
        bool _isTrustContract,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell {
        require(checkBWO(_msgSender()), "World: address is not BWO");
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
                            "trustContractBWO(uint256 id,address contract,bool flag,address sender,uint256 nonce,uint256 deadline)"
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

    //account
    function trustWorld(uint256 _id, bool _isTrustWorld) public override onlyShell {
        metaverse.checkSender(_id, _msgSender());
        _trustWorld(_id, _isTrustWorld, false, _msgSender());
    }

    function trustWorldBWO(
        uint256 _id,
        bool _isTrustWorld,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell {
        require(checkBWO(_msgSender()), "World: address is not BWO");
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
                        keccak256("trustWorldBWO(uint256 id,bool flag,address sender,uint256 nonce,uint256 deadline)"),
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
    ) internal {
        worldStorage.setTrustWorld(_id, _isTrustWorld);
        emit TrustWorld(_id, _isTrustWorld, _isBWO, _sender, getNonce(_sender));
        worldStorage.IncrementNonce(_sender);
    }

    //asset
    /**
     * @dev See {IWorld-getAssets}.
     */
    function getAssets() public view override returns (address[] memory) {
        return metaStorage.getAssets();
    }

    // Owner functions
    function registerAsset(address _address) public onlyOwner {
        require(_address != address(0), "World: zero address");
        require(worldStorage.assetContains(_address) == false, "World: asset is exist");
        require(IAsset(_address).worldAddress() == address(this), "World: world address is not match");
        metaStorage.addAsset(_address);
        emit RegisterAsset(_address, IAsset(_address).name(), IAsset(_address).protocol());
    }

    function disableAsset(address _address) public onlyOwner {
        worldStorage.disableAsset(_address);
        emit DisableAsset(_address);
    }

    function enableAsset(address _address) public onlyOwner {
        worldStorage.enableAsset(_address);
        emit EnableAsset(_address);
    }

    function addSafeContract(address _address) public onlyOwner {
        require(_address != address(0), "World: zero address");
        worldStorage.addSafeContract(_address);
        emit AddSafeContract(_address);
    }

    function removeSafeContract(address _address) public onlyOwner {
        worldStorage.removeSafeContract(_address);
        emit RemoveSafeContract(_address);
    }

    // utils
    function checkBWO(address _address) public view returns (bool) {
        return (worldStorage.isOperator(_address) || owner() == _address);
    }

    function checkAsset(address _address) public view returns (bool)  {
        return worldStorage.isEnabledAsset(_address);
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(deadline == 0 || block.timestamp < deadline, "Metaverse: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "Metaverse: recoverSig failed");
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

}
