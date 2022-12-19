//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IAsset.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IMetaverse.sol";
import "../interfaces/IAcertContract.sol";
import "./WorldStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract WorldCore is IWorldCore, CoreContract, IAcertContract, EIP712 {
    string public worldName;
    string public worldVersion;
    WorldStorage worldStorage;
    IMetaverse metaverse;

    constructor(
        string memory _name,
        string memory _version,
        address _metaverse,
        address _worldStorage
    ) EIP712(_name, _version) {
        metaverse = IMetaverse(_metaverse);
        worldName = _name;
        worldVersion = _version;
        worldStorage = WorldStorage(_worldStorage);
    }

    function shell() public view returns (WorldShell) {
        return WorldShell(shellContract);
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() public view override returns (address) {
        return address(metaverse);
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
    function trustContract_(
        address _msgSender,
        uint256 _id,
        address _contract,
        bool _isTrustContract
    ) public override onlyShell {
        checkAddressIsNotZero(_contract);
        metaverse.checkSender(_id, _msgSender);
        _trustContract(_id, _contract, _isTrustContract, false, _msgSender);
    }

    function trustContractBWO_(
        address _msgSender,
        uint256 _id,
        address _contract,
        bool _isTrustContract,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell {
        require(checkBWO(_msgSender), "World: address is not BWO");
        checkAddressIsNotZero(_contract);
        trustContractBWOParamsVerify(_id, _contract, _isTrustContract, sender, deadline, signature);
        _trustContract(_id, _contract, _isTrustContract, true, sender);
    }

    function trustContractBWOParamsVerify(
        uint256 _id,
        address _contract,
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
                        _contract,
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
        shell().emitTrustContract(_id, _address, _isTrustContract, _isBWO, _sender, getNonce(_sender));
        worldStorage.IncrementNonce(_sender);
    }

    //account
    function trustWorld_(
        address _msgSender,
        uint256 _id,
        bool _isTrustWorld
    ) public override onlyShell {
        metaverse.checkSender(_id, _msgSender);
        _trustWorld(_id, _isTrustWorld, false, _msgSender);
    }

    function trustWorldBWO_(
        address _msgSender,
        uint256 _id,
        bool _isTrustWorld,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell {
        require(checkBWO(_msgSender), "World: address is not BWO");
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
        shell().emitTrustWorld(_id, _isTrustWorld, _isBWO, _sender, getNonce(_sender));
        worldStorage.IncrementNonce(_sender);
    }

    //asset
    /**
     * @dev See {IWorld-getAssets}.
     */
    function getAssets() public view override returns (address[] memory) {
        return worldStorage.getAssets();
    }

    /**
     * @dev See {IWorld-isEnabledAsset}.
     */
    function isEnabledAsset(address _address) public view override returns (bool) {
        return worldStorage.isEnabledAsset(_address);
    }

    //safeContract
    /**
     * @dev See {IWorld-getSafeContracts}.
     */
    function getSafeContracts() public view override returns (address[] memory) {
        return worldStorage.getSafeContracts();
    }

    /**
     * @dev See {IWorld-isSafeContract}.
     */
    function isSafeContract(address _address) public view override returns (bool) {
        return worldStorage.isSafeContract(_address);
    }

    function addOperator(address _operator) public onlyOwner {
        checkAddressIsNotZero(_operator);
        worldStorage.setOperator(_operator, true);
        shell().emitAddOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner {
        worldStorage.setOperator(_operator, false);
        shell().emitRemoveOperator(_operator);
    }

    /**
     * @dev See {IWorld-checkBWO}.
     */
    function checkBWO(address _address) public view override returns (bool) {
        return (worldStorage.isOperator(_address) || owner() == _address);
    }

    function getNonce(address _address) public view override returns (uint256) {
        return worldStorage.nonces(_address);
    }

    // Owner functions
    function registerAsset(address _address) public onlyOwner {
        checkAddressIsNotZero(_address);
        require(worldStorage.assetContains(_address) == false, "World: asset is exist");
        require(IAsset(_address).worldAddress() == address(shellContract), "World: world address is not match");
        worldStorage.addAsset(_address);
        shell().emitRegisterAsset(_address);
    }

    function disableAsset(address _address) public onlyOwner {
        worldStorage.disableAsset(_address);
        shell().emitDisableAsset(_address);
    }

    function enableAsset(address _address) public onlyOwner {
        worldStorage.enableAsset(_address);
        shell().emitEnableAsset(_address);
    }

    function addSafeContract(address _address) public onlyOwner {
        checkAddressIsNotZero(_address);
        worldStorage.addSafeContract(_address);
        shell().emitAddSafeContract(_address);
    }

    function removeSafeContract(address _address) public onlyOwner {
        worldStorage.removeSafeContract(_address);
        shell().emitRemoveSafeContract(_address);
    }

    // utils
    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(deadline == 0 || block.timestamp < deadline, "World: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "World: recoverSig failed");
    }

    function checkAddressIsNotZero(address _address) internal pure {
        require(_address != address(0), "World: address is zero");
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }
}
