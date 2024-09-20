//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IAsset.sol";
import "../interfaces/IVChain.sol";
import "../interfaces/ShellCore.sol";
import "../interfaces/IAcertContract.sol";
import "./VChain.sol";
import "./VChainStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract VChainCore is IVChainCore, CoreContract, IAcertContract, EIP712 {
    /**
     * @dev See {IVChain-name}.
     */
    string public override name;
    /**
     * @dev See {IVChain-version}.
     */
    string public override version;
    uint256 public immutable _startId;
    bool public quickUFA;

    VChainStorage public metaStorage;

    modifier onlyAdmin() {
        require(metaStorage.admin() == _msgSender(), "VChain: caller is not the admin");
        _;
    }

    constructor(
        string memory name_,
        string memory version_,
        uint256 startId_,
        address metaStorage_
    ) EIP712(name_, version_) {
        name = name_;
        version = version_;
        _startId = startId_;
        metaStorage = VChainStorage(metaStorage_);
        quickUFA = true;
    }

    function shell() public view returns (VChain) {
        return VChain(shellContract);
    }

    /**
     * @dev See {IAcertContract-vchainAddress}.
     */
    function vchainAddress() public view override returns (address) {
        return IAcertContract(shellContract).vchainAddress();
    }

    // account
    /**
     * @dev See {IVChainCore-createAccount_}.
     */
    function createAccount_(
        address _msgSender,
        address _address
    ) public override onlyShell returns (uint256 id) {
        return _createAccount(_address, false, _msgSender);
    }

    /**
     * @dev See {IVChainCore-createAccountBWO_}.
     */
    function createAccountBWO_(
        address _msgSender,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override onlyShell returns (uint256 id) {
        require(checkBWO(_msgSender), "VChain: address is not BWO");
        createAccoutBWOParamsVerfiy(_address, sender, deadline, signature);
        return _createAccount(_address, true, sender);
    }

    function createAccoutBWOParamsVerfiy(
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public view returns (bool) {
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "createAccountBWO(address _address,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _address,
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

    function _createAccount(
        address _address,
        bool _isBWO,
        address _sender
    ) private returns (uint256 id) {
        metaStorage.IncrementTotalAccount();
        id = metaStorage.totalAccount() + _startId;
        metaStorage.setAccount(id);

        checkAddressIsNotZero(_address);
        checkAddressIsNotUsed(_address);
        metaStorage.addAuthAddress(id, _address);
        shell().emitCreateAccount(id, _address, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_address);
        if (_sender != _address) {
            metaStorage.IncrementNonce(_sender);
        }
    }

    /**
     * @dev Only Admin can call this function to add a authAddress to account. (with auth)
     */
    function addAccountAuthAddress(
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes calldata signature
    ) public onlyAdmin {
        require(accountIsExist(_id), "VChain: Account does not exist");
        checkAuthAddressSignature(_id, _address, deadline, signature);
        _addAuthAddress(_id, _address, false, msg.sender);
    }

    /**
     * @dev See {IVChainCore-addAuthAddress_}.
     */
    function addAuthAddress_(
        address _msgSender,
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes calldata signature
    ) public override onlyShell {
        checkSender(_id, _msgSender);
        checkAuthAddressSignature(_id, _address, deadline, signature);
        _addAuthAddress(_id, _address, false, _msgSender);
    }

    /**
     * @dev See {IVChainCore-addAuthAddressBWO_}.
     */
    function addAuthAddressBWO_(
        address _msgSender,
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature,
        bytes calldata authSignature
    ) public override onlyShell {
        require(checkBWO(_msgSender), "VChain: address is not BWO");

        addAuthAddressBWOParamsVerfiy(_id, _address, sender, deadline, signature);
        checkAuthAddressSignature(_id, _address, deadline, authSignature);
        _addAuthAddress(_id, _address, true, sender);
    }

    function addAuthAddressBWOParamsVerfiy(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature
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
                            "addAuthAddressBWO(uint256 id,address addr,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _id,
                        _address,
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

    function checkAuthAddressSignature(
        uint256 _id,
        address _address,
        uint256 deadline,
        bytes calldata signature
    ) public view returns (bool) {
        uint256 nonce = getNonce(_address);
        _recoverSig(
            deadline,
            _address,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("AddAuth(uint256 id,address addr,uint256 nonce,uint256 deadline)"),
                        _id,
                        _address,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        return true;
    }

    function _addAuthAddress(
        uint256 _id,
        address _address,
        bool _isBWO,
        address _sender
    ) private {
        checkAddressIsNotZero(_address);
        checkAddressIsNotUsed(_address);
        metaStorage.addAuthAddress(_id, _address);

        shell().emitAddAuthAddress(_id, _address, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_address);
        metaStorage.IncrementNonce(_sender);
    }

    /**
     * @dev See {IVChainCore-removeAuthAddress_}.
     */
    function removeAuthAddress_(
        address _msgSender,
        uint256 _id,
        address _address
    ) public override onlyShell {
        checkAddressIsNotZero(_address);
        checkSender(_id, _msgSender);
        _removeAuthAddress(_id, _address, false, _msgSender);
    }

    /**
     * @dev See {IVChainCore-removeAuthAddressBWO_}.
     */
    function removeAuthAddressBWO_(
        address _msgSender,
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override onlyShell {
        require(checkBWO(_msgSender), "VChain: address is not BWO");
        checkAddressIsNotZero(_address);
        removeAuthAddressBWOParamsVerfiy(_id, _address, sender, deadline, signature);
        _removeAuthAddress(_id, _address, true, sender);
    }

    function removeAuthAddressBWOParamsVerfiy(
        uint256 _id,
        address _address,
        address sender,
        uint256 deadline,
        bytes calldata signature
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
                            "removeAuthAddressBWO(uint256 id,address addr,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        _id,
                        _address,
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

    function _removeAuthAddress(
        uint256 _id,
        address _address,
        bool _isBWO,
        address _sender
    ) private {
        require(_address != _sender, "VChain: AuthAddress can not remove itself");
        metaStorage.removeAuthAddress(_id, _address);
        shell().emitRemoveAuthAddress(_id, _address, _isBWO, _sender, getNonce(_sender));
        metaStorage.IncrementNonce(_sender);
    }

    /**
     * @dev See {IVChain-getAccountIdByAddress}.
     */
    function getAccountIdByAddress(address _address) public view override returns (uint256 _id) {
        return metaStorage.authToId(_address);
    }

    /**
     * @dev See {IVChain-getAddressByAccountId}.
     */
    function getAddressByAccountId(uint256 _id) public view override returns (address _address) {
        return metaStorage.getAccountAddress(_id);
    }

    /**
     * @dev See {IVChain-getAccountAuthAddress}.
     */
    function getAccountAuthAddress(uint256 _id) public view override returns (address[] memory) {
        return metaStorage.getAuthAddresses(_id);
    }

    /**
     * @dev See {IVChain-accountIsExist}.
     */
    function accountIsExist(uint256 _id) public view override returns (bool _isExist) {
        return metaStorage.accountIsExist(_id);
    }

    /**
     * @dev See {IVChain-checkSender}.
     */
    function checkSender(uint256 _id, address _sender) public view override returns (bool) {
        require(accountIsExist(_id), "VChain: Account does not exist");
        require(metaStorage.authAddressContains(_id, _sender), "VChain: Sender is not authorized");
        return true;
    }

    /**
     * @dev See {IVChain-getTotalAccount}.
     */
    function getTotalAccount() public view override returns (uint256) {
        return metaStorage.totalAccount();
    }

    /**
     * @dev See {IVChain-getNonce}.
     */
    function getNonce(address _address) public view override returns (uint256) {
        return metaStorage.nonces(_address);
    }

    //asset
    /**
     * @dev See {IVChain-getAssets}.
     */
    function getAssets() public view override returns (address[] memory) {
        return metaStorage.getAssets();
    }

    /**
     * @dev See {IVChain-isEnabledAsset}.
     */
    function isEnabledAsset(address _address) public view override returns (bool) {
        return metaStorage.isEnabledAsset(_address);
    }

    //safeContract
    /**
     * @dev See {IVChain-getSafeContracts}.
     */
    function getSafeContracts() public view override returns (address[] memory) {
        return metaStorage.getSafeContracts();
    }

    /**
     * @dev See {IVChain-isSafeContract}.
     */
    function isSafeContract(address _address) public view override returns (bool) {
        return metaStorage.isSafeContract(_address);
    }

    /**
     * @dev See {IVChain-checkBWO}.
     */
    function checkBWO(address _address) public view override returns (bool) {
        return (metaStorage.isOperator(_address) || owner() == _address);
    }

    function setAdmin(address _address) public onlyOwner {
        checkAddressIsNotZero(_address);
        metaStorage.setAdmin(_address);
        shell().emitSetAdmin(_address);
    }

    function getAdmin() public view returns (address) {
        return metaStorage.admin();
    }

    function addOperator(address _operator) public onlyOwner {
        checkAddressIsNotZero(_operator);
        metaStorage.setOperator(_operator, true);
        shell().emitAddOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner {
        metaStorage.setOperator(_operator, false);
        shell().emitRemoveOperator(_operator);
    }

    function registerAsset(address _address) public onlyOwner {
        checkAddressIsNotZero(_address);
        require(metaStorage.assetContains(_address) == false, "VChain: asset is exist");
        require(IAcertContract(_address).vchainAddress() == address(shellContract), "VChain: vchain address is not match");
        metaStorage.addAsset(_address);
        shell().emitRegisterAsset(_address);
    }

    function disableAsset(address _address) public onlyOwner {
        metaStorage.disableAsset(_address);
        shell().emitDisableAsset(_address);
    }

    function enableAsset(address _address) public onlyOwner {
        metaStorage.enableAsset(_address);
        shell().emitEnableAsset(_address);
    }

    function addSafeContract(address _address) public onlyOwner {
        checkAddressIsNotZero(_address);
        metaStorage.addSafeContract(_address);
        shell().emitAddSafeContract(_address);
    }

    function removeSafeContract(address _address) public onlyOwner {
        metaStorage.removeSafeContract(_address);
        shell().emitRemoveSafeContract(_address);
    }

    // utils
    // function checkBWO(address _address) public view returns (bool) {
    //     return (metaStorage.isOperator(_address) || owner() == _address);
    // }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes calldata signature
    ) internal view {
        require(deadline == 0 || block.timestamp < deadline, "VChain: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "VChain: recoverSig failed");
    }

    function checkAddressIsNotUsed(address _address) internal view {
        require(getAccountIdByAddress(_address) == 0, "VChain: new address has been used");
    }

    function checkAddressIsNotZero(address _address) internal pure {
        require(_address != address(0), "VChain: address is zero");
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }
}
