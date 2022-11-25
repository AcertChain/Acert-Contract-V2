//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IAsset20.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IMetaverse.sol";
import "../interfaces/IAcertContract.sol";
import "./Asset20Storage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Asset20Core is IAsset20Core, CoreContract, IAcertContract, EIP712 {
    IWorld public world;
    IMetaverse public metaverse;
    Asset20Storage public storageContract;

    string private assetName;
    string private assetSymbol;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory version_,
        address _world,
        address _storage
    ) EIP712(name_, version_) {
        assetName = name_;
        assetSymbol = symbol_;
        world = IWorld(_world);
        storageContract = Asset20Storage(_storage);
        metaverse = IMetaverse(IAcertContract(_world).metaverseAddress());
    }

    function shell() public view returns (Asset20Shell) {
        return Asset20Shell(shellContract);
    }

    function updateWorld(address _address) public onlyOwner {
        require(address(metaverse) == IAcertContract(_address).metaverseAddress(), "Asset20: metaverse not match");
        world = IWorld(_address);
    }

    /**
     * @dev See {IAcertContract-metaverseAddress}.
     */
    function metaverseAddress() external view override returns (address) {
        return address(metaverse);
    }

    /**
     * @dev See {IERC20-symbol}.
     */
    function name() public view override returns (string memory) {
        return assetName;
    }

    /**
     * @dev See {IERC20-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return assetSymbol;
    }

    /**
     * @dev See {IERC20-decimals}.
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return storageContract.totalSupply();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        _checkAddrIsNotZero(owner, "Asset20: address zero is not a valid owner");
        return _balanceOf(_getAccountIdByAddress(owner));
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowance(_getAccountIdByAddress(owner), spender);
    }

    /**
     * @dev See {IAsset-protocol}.
     */
    function protocol() external pure virtual override returns (IAsset.ProtocolEnum) {
        return IAsset.ProtocolEnum.ASSET20;
    }

    function worldAddress() external view override returns (address) {
        return address(world);
    }

    function getNonce(address account) public view virtual override returns (uint256) {
        return storageContract.nonces(account);
    }

    /**
     * @dev See {IAsset20-balanceOf}.
     */
    function balanceOf(uint256 account) public view virtual override returns (uint256) {
        _checkIdIsNotZero(account, "Asset20: id zero is not a valid owner");
        return _balanceOf(account);
    }

    /**
     * @dev See {IAsset20-allowance}.
     */
    function allowance(uint256 ownerId, address spender) public view virtual override returns (uint256) {
        if (_isTrust(spender, ownerId)) {
            return type(uint256).max;
        }
        return storageContract.allowancesById(ownerId, spender);
    }

    // transfer
    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer_(address _msgSender, address to, uint256 amount) public override onlyShell returns (bool) {
        _transfer(_msgSender, to, amount, _msgSender);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom_(
        address _msgSender,
        address from,
        address to,
        uint256 amount
    ) public override onlyShell returns (bool) {
        if (_getAccountIdByAddress(_msgSender) != _getAccountIdByAddress(from)) {
            _spendAllowance(_getAccountIdByAddress(from), from, _msgSender, amount, false, _msgSender);
        }
        _transfer(from, to, amount, _msgSender);
        return true;
    }

    function _spendAllowance(
        uint256 ownerId,
        address owner,
        address spender,
        uint256 amount,
        bool isBWO,
        address sender
    ) internal virtual {
        uint256 currentAllowance = allowance(ownerId, sender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Asset20: insufficient allowance");
            unchecked {
                _approveId(ownerId, owner, spender, currentAllowance - amount, isBWO, sender);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount,
        address sender
    ) internal virtual {
        _checkAddrIsNotZero(from, "Asset20: transfer from the zero address");
        _transferAsset(_getOrCreateAccountId(from), _getOrCreateAccountId(to), amount, false, sender, from, to);
    }

    /**
     * @dev See {IAsset-transferFrom}.
     */
    function transferFrom_(
        address _msgSender,
        uint256 fromAccount,
        uint256 toAccount,
        uint256 amount
    ) public override onlyShell returns (bool) {
        if (_getAccountIdByAddress(_msgSender) != fromAccount) {
            _spendAllowance(
                fromAccount,
                _getAddressByAccountId(fromAccount),
                _msgSender,
                amount,
                false,
                _msgSender
            );
        }

        _transferAsset(
            fromAccount,
            toAccount,
            amount,
            false,
            _msgSender,
            _getAddressByAccountId(fromAccount),
            _getAddressByAccountId(toAccount)
        );
        return true;
    }

    /**
     * @dev See {IAsset-transferBWO}.
     */
    function transferFromBWO_(
        address _msgSender,
        uint256 fromAccount,
        uint256 toAccount,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell returns (bool) {
        _checkBWO(_msgSender);
        transferFromBWOParamsVerify(fromAccount, toAccount, amount, sender, deadline, signature);

        if (_getAccountIdByAddress(sender) != fromAccount) {
            _spendAllowance(fromAccount, _getAddressByAccountId(fromAccount), sender, amount, true, sender);
        }
        _transferAsset(
            fromAccount,
            toAccount,
            amount,
            true,
            sender,
            _getAddressByAccountId(fromAccount),
            _getAddressByAccountId(toAccount)
        );
        return true;
    }

    function transferFromBWOParamsVerify(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "transferFromBWO(uint256 from,uint256 to,uint256 amount,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        fromAccount,
                        toAccount,
                        amount,
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

    function _transferAsset(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 amount,
        bool _isBWO,
        address _sender,
        address _fromAddr,
        address _toAddr
    ) internal virtual {
        require(_assetIsEnabled(), "Asset20: asset is not enabled");
        require(!_accountIsFreeze(fromAccount), "Asset20: transfer from is frozen");
        if (toAccount == 0) {
            return burn_(fromAccount, amount, _sender);
        }
        require(_accountIsExist(toAccount), "Asset20: to account is not exist");

        uint256 fromBalance = _balanceOf(fromAccount);
        require(fromBalance >= amount, "Asset20: transfer amount exceeds balance");
        _setBalance(fromAccount, fromBalance - amount);
        _setBalance(toAccount, _balanceOf(toAccount) + amount);

        shell().emitTransfer(_fromAddr, _toAddr, amount);
        shell().emitAssetTransfer(fromAccount, toAccount, amount, _isBWO, _sender, getNonce(_sender));
        _incrementNonce(_sender);
    }

    // approve
    /**
     * @dev See {IERC20-approve}.
     */
    function approve_(address _msgSender, address spender, uint256 amount) public override onlyShell returns (bool) {
        _approveId(_getOrCreateAccountId(_msgSender), _msgSender, spender, amount, false, _msgSender);
        return true;
    }

    /**
     * @dev See {IAsset20-approve}.
     */
    function approve_(
        address _msgSender,
        uint256 ownerId,
        address spender,
        uint256 amount
    ) public override onlyShell returns (bool) {
        _checkAddrIsNotZero(spender, "Asset20: approve to the zero address");
        _checkSender(ownerId, _msgSender);
        _approveId(ownerId, _getAddressByAccountId(ownerId), spender, amount, false, _msgSender);
        return true;
    }

    /**
     * @dev See {IAsset20-approveBWO}.
     */
    function approveBWO_(
        address _msgSender,
        uint256 ownerId,
        address spender,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public override onlyShell returns (bool) {
        _checkBWO(_msgSender);
        approveBWOParamsVerify(ownerId, spender, amount, sender, deadline, signature);
        _approveId(ownerId, _getAddressByAccountId(ownerId), spender, amount, true, sender);
        return true;
    }

    function approveBWOParamsVerify(
        uint256 ownerId,
        address spender,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        _checkSender(ownerId, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "approveBWO(uint256 ownerId,address spender,uint256 amount,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        ownerId,
                        spender,
                        amount,
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

    function _approveId(
        uint256 ownerId,
        address owner,
        address spender,
        uint256 amount,
        bool isBWO,
        address sender
    ) internal virtual onlyShell {
        require(_assetIsEnabled(), "Asset20: asset is not enabled");
        require(!_accountIsFreeze(ownerId), "Asset20: approve owner is frozen");
        _checkAddrIsNotZero(owner, "Asset20: approve from the zero address");
        _checkAddrIsNotZero(spender, "Asset20: approve to the zero address");

        storageContract.setAllowanceById(ownerId, spender, amount);
        shell().emitApproval(owner, spender, amount);
        shell().emitAssetApproval(ownerId, spender, amount, isBWO, sender, getNonce(sender));
        _incrementNonce(sender);
    }

// mint & burn
    function mint_(address _msgSender, uint256 account, uint256 amount) public override onlyShell {
        _checkIdIsNotZero(account, "Asset20: mint to the zero Id");
        require(_accountIsExist(account), "Asset20: to account is not exist");

        _setBalance(account, _balanceOf(account) + amount);
        _setTotalSupply(totalSupply() + amount);
        shell().emitTransfer(address(0), _getAddressByAccountId(account), amount);
        shell().emitAssetTransfer(0, account, amount, false, _msgSender, getNonce(_msgSender));
        _incrementNonce(_msgSender);
    }

    function burn_(
        uint256 account,
        uint256 amount,
        address sender
    ) internal virtual {
        _checkIdIsNotZero(account, "Asset20: burn from the zero Id");
        require(_accountIsExist(account), "Asset20: to account is not exist");

        uint256 accountBalance = _balanceOf(account);
        require(accountBalance >= amount, "Asset20: burn amount exceeds balance");
        _setBalance(account, accountBalance - amount);
        _setTotalSupply(totalSupply() - amount);
        shell().emitTransfer(_getAddressByAccountId(account), address(0), amount);
        shell().emitAssetTransfer(account, 0, amount, false, sender, getNonce(sender));
        _incrementNonce(sender);
    }

    function _checkIdIsNotZero(uint256 _id, string memory _msg) internal pure {
        require(_id != 0, _msg);
    }

    function _checkAddrIsNotZero(address _addr, string memory _msg) internal pure {
        require(_addr != address(0), _msg);
    }

    function _incrementNonce(address account) internal {
        storageContract.incrementNonce(account);
    }

    function _balanceOf(uint256 account) internal view returns (uint256) {
        return storageContract.balancesById(account);
    }

    function _setBalance(uint256 account, uint256 amount) internal {
        storageContract.setBalanceById(account, amount);
    }

    function _setTotalSupply(uint256 amount) internal {
        storageContract.setTotalSupply(amount);
    }

    function _getAccountIdByAddress(address _address) internal view returns (uint256) {
        return metaverse.getAccountIdByAddress(_address);
    }

    function _getOrCreateAccountId(address _address) internal returns (uint256) {
        if (_address != address(0)) {
            return 0;
        } else if(metaverse.getAccountIdByAddress(_address) == 0) {
            return metaverse.createAccount(_address, false);
        } else {
            return metaverse.getAccountIdByAddress(_address);
        }
    }

    function _getAddressByAccountId(uint256 _id) internal view returns (address) {
        return metaverse.getAddressByAccountId(_id);
    }

    function _assetIsEnabled() internal view returns (bool) {
        return world.isEnabledAsset(shellContract);
    }

    function _accountIsFreeze(uint256 _id) internal view returns (bool) {
        return metaverse.accountIsFreeze(_id);
    }

    function _checkSender(uint256 ownerId, address sender) internal view {
        metaverse.checkSender(ownerId, sender);
    }

    function _accountIsExist(uint256 _id) internal view returns (bool) {
        return metaverse.accountIsExist(_id);
    }

    function _checkBWO(address _sender) internal view {
        require(world.checkBWO(_sender), "Asset20: BWO is not allowed");
    }

    function _isTrust(address _address, uint256 _id) internal view returns (bool) {
        return world.isTrust(_address, _id);
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(deadline == 0 || block.timestamp < deadline, "Asset20: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "Asset20: recoverSig failed");
    }
}
