//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IAsset721.sol";
import "../interfaces/IVChain.sol";
import "../interfaces/IAcertContract.sol";
import "./Asset721.sol";
import "./Asset721Storage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Asset721Core is IAsset721Core, CoreContract, IAcertContract, EIP712 {
    //    using Address for address;
    using Strings for uint256;

    string public override name;
    string public version;
    string public override symbol;
    string private _tokenURI;

    IVChain public vchain;
    Asset721Storage public storageContract;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory version_,
        string memory tokenURI_,
        address vchain_,
        address storage_
    ) EIP712(name_, version_) {
        name = name_;
        version = version_;
        symbol = symbol_;
        _tokenURI = tokenURI_;
        storageContract = Asset721Storage(storage_);
        vchain = IVChain(vchain_);
    }

    function shell() public view returns (Asset721) {
        return Asset721(shellContract);
    }

    /**
     * @dev See {IAcertContract-vchainAddress}.
     */
    function vchainAddress() external view override returns (address) {
        return address(vchain);
    }

    /**
     * @dev See {IAsset-protocol}.
     */
    function protocol() external pure virtual override returns (IAsset.ProtocolEnum) {
        return IAsset.ProtocolEnum.ASSET721;
    }

    function getNonce(address account) public view virtual override returns (uint256) {
        return storageContract.nonces(account);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_tokenURI, tokenId.toString()));
    }

    function setTokenURI(string memory uri) public onlyOwner {
        _tokenURI = uri;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        _checkAddrIsNotZero(owner, "Asset721: address zero is not a valid owner");
        return _balancesById(_getAccountIdByAddress(owner));
    }

    /**
     * @dev See {IAsset721-balanceOf}.
     */
    function balanceOf(uint256 accountId) public view virtual override returns (uint256) {
        _checkIdIsNotZero(accountId, "Asset721: id zero is not a valid owner");
        return _balancesById(accountId);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address owner) {
        owner = _getAddressByAccountId(_ownersById(tokenId));
        _checkAddrIsNotZero(owner, "Asset721: owner query for nonexistent token");
    }

    /**
     * @dev See {IAsset721-ownerAccountOf}.
     */
    function ownerAccountOf(uint256 tokenId) public view virtual override returns (uint256 ownerId) {
        ownerId = _ownersById(tokenId);
        _checkIdIsNotZero(ownerId, "Asset721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721-approve}.
     * @dev See {IAsset721-approve}.
     */
    function approve_(
        address _msgSender,
        address spender,
        uint256 tokenId
    ) public override onlyShell {
        uint256 ownerId = ownerAccountOf(tokenId);
        require(
            _getAccountIdByAddress(_msgSender) == ownerId || isApprovedForAll(ownerId, _msgSender),
            "Asset721: approve caller is not owner or approved for all"
        );
        _approve(spender, tokenId, false, _msgSender);
    }

    function approveBWO_(
        address _msgSender,
        address spender,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override onlyShell {
        _checkBWO(_msgSender);
        approveBWOParamsVerify(spender, tokenId, sender, deadline, signature);
        _approve(spender, tokenId, true, sender);
    }

    function approveBWOParamsVerify(
        address spender,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public view returns (bool) {
        uint256 ownerId = ownerAccountOf(tokenId);
        require(
            _getAccountIdByAddress(sender) == ownerId || isApprovedForAll(ownerId, sender),
            "Asset721: approve caller is not owner or approved for all"
        );
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "approveBWO(address spender,uint256 tokenId,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        spender,
                        tokenId,
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

    function _approve(
        address spender,
        uint256 tokenId,
        bool isBWO,
        address sender
    ) internal virtual {
        uint256 ownerId = ownerAccountOf(tokenId);
        require(_assetIsEnabled(), "Asset721: asset is not enabled");
        require(_getOrCreateAccountId(spender) != ownerId, "Asset721: approval to current account");

        _setTokenApprovalById(tokenId, spender);
        shell().emitApproval(ownerOf(tokenId), spender, tokenId);
        shell().emitAssetApproval(ownerId, spender, tokenId, isBWO, sender, getNonce(sender));
        _incrementNonce(sender);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "Asset721: approved query for nonexistent token");
        return storageContract.tokenApprovalsById(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll_(
        address _msgSender,
        address operator,
        bool approved
    ) public override onlyShell {
        uint256 accountId = _getOrCreateAccountId(_msgSender);
        _checkIdIsNotZero(accountId, "Asset721: approveForAll query for nonexistent account");
        _setApprovalForAll(accountId, operator, approved, false, _msgSender);
    }

    function setApprovalForAll_(
        address _msgSender,
        uint256 accountId,
        address operator,
        bool approved
    ) public override onlyShell {
        _checkIdIsNotZero(accountId, "Asset721: approveForAll query for nonexistent account");
        _checkSender(accountId, _msgSender);
        _setApprovalForAll(accountId, operator, approved, false, _msgSender);
    }

    function setApprovalForAllBWO_(
        address _msgSender,
        uint256 accountId,
        address operator,
        bool approved,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override onlyShell {
        _checkBWO(_msgSender);
        setApprovalForAllBWOParamsVerify(accountId, operator, approved, sender, deadline, signature);
        _setApprovalForAll(accountId, operator, approved, true, sender);
    }

    function setApprovalForAllBWOParamsVerify(
        uint256 accountId,
        address operator,
        bool approved,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public view returns (bool) {
        _checkSender(accountId, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "setApprovalForAllBWO(uint256 from,address to,bool approved,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        accountId,
                        operator,
                        approved,
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

    function _setApprovalForAll(
        uint256 accountId,
        address operator,
        bool approved,
        bool isBWO,
        address sender
    ) internal virtual {
        _checkIdIsNotZero(accountId, "Asset721: id zero is not a valid owner");
        require(_assetIsEnabled(), "Asset721: asset is not enabled");
        _checkAddrIsNotZero(operator, "Asset721: approve to the zero address");
        require(_getAccountIdByAddress(operator) != accountId, "Asset721: approval to current account");

        storageContract.setOperatorApprovalById(accountId, operator, approved);
        shell().emitApprovalForAll(sender, operator, approved);
        shell().emitAssetApprovalForAll(accountId, operator, approved, isBWO, sender, getNonce(sender));
        _incrementNonce(sender);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return isApprovedForAll(_getAccountIdByAddress(owner), operator);
    }

    function isApprovedForAll(uint256 ownerId, address operator) public view virtual override returns (bool) {
        _checkIdIsNotZero(ownerId, "Asset721: id zero is not a valid owner");
        if (_isSafeContract(operator)) {
            return true;
        }
        return storageContract.operatorApprovalsById(ownerId, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom_(
        address _msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public override onlyShell {
        require(_isApprovedOrOwner(_msgSender, tokenId), "Asset721: transfer caller is not owner nor approved");
        if (to == address(0)) {
            _burn(tokenId, _msgSender);
        } else {
            _transfer(_getOrCreateAccountId(from), _getOrCreateAccountId(to), tokenId, false, _msgSender, from, to);
        }
    }

    function transferFrom_(
        address _msgSender,
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId
    ) public override onlyShell {
        require(_isApprovedOrOwner(_msgSender, tokenId), "Asset721: transfer caller is not owner nor approved");
        if (toAccount == 0) {
            _burn(tokenId, _msgSender);
        } else {
            _transfer(
                fromAccount,
                toAccount,
                tokenId,
                false,
                _msgSender,
                _getAddressByAccountId(fromAccount),
                _getAddressByAccountId(toAccount)
            );
        }
    }

    function transferFromBWO_(
        address _msgSender,
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override onlyShell {
        _checkBWO(_msgSender);
        transferFromBWOParamsVerify(fromAccount, toAccount, tokenId, sender, deadline, signature);
        if (toAccount == 0) {
            _burn(tokenId, sender);
        } else {
            _transfer(
                fromAccount,
                toAccount,
                tokenId,
                true,
                sender,
                _getAddressByAccountId(fromAccount),
                _getAddressByAccountId(toAccount)
            );
        }
    }

    function transferFromBWOParamsVerify(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public view returns (bool) {
        require(_isApprovedOrOwner(sender, tokenId), "Asset721: transfer caller is not owner nor approved");
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "transferFromBWO(uint256 from,uint256 to,uint256 tokenId,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        fromAccount,
                        toAccount,
                        tokenId,
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

    function _transfer(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId,
        bool isBWO,
        address sender,
        address _fromAddr,
        address _toAddr
    ) internal virtual {
        require(ownerAccountOf(tokenId) == fromAccount, "Asset721: transfer from incorrect owner");
        require(_assetIsEnabled(), "Asset721: asset is not enabled");
        if (toAccount == 0) {
            return _burn(tokenId, sender);
        }
        require(_accountIsExist(toAccount), "Asset721: to account is not exist");
        _checkIdIsNotZero(toAccount, "Asset721: transfer to the zero id");

        // Clear approvals from the previous owner
        _setTokenApprovalById(tokenId, address(0));

        _setBalanceById(fromAccount, _balancesById(fromAccount) - 1);
        _setBalanceById(toAccount, _balancesById(toAccount) + 1);
        storageContract.setOwnerById(tokenId, toAccount);

        shell().emitTransfer(_fromAddr, _toAddr, tokenId);
        shell().emitAssetTransfer(fromAccount, toAccount, tokenId, isBWO, sender, getNonce(sender));

        _incrementNonce(sender);
    }

    function safeTransferFrom_(
        address _msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public override onlyShell {
        safeTransferFrom_(_msgSender, from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom_(
        address _msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyShell {
        safeTransferFrom_(_msgSender, _getOrCreateAccountId(from), _getOrCreateAccountId(to), tokenId, data);
    }

    function safeTransferFrom_(
        address _msgSender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyShell {
        require(_isApprovedOrOwner(_msgSender, tokenId), "Asset721: transfer caller is not owner nor approved");
        if (to == 0) {
            _burn(tokenId, _msgSender);
        } else {
            _safeTransfer(_msgSender, from, to, tokenId, false, _msgSender, data);
        }
    }

    function safeTransferFromBWO_(
        address _msgSender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public override onlyShell {
        _checkBWO(_msgSender);
        safeTransferFromBWOParamsVerify(from, to, tokenId, data, sender, deadline, signature);

        if (to == 0) {
            _burn(tokenId, sender);
        } else {
            _safeTransfer(_msgSender, from, to, tokenId, true, sender, data);
        }
    }

    function safeTransferFromBWOParamsVerify(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
        address sender,
        uint256 deadline,
        bytes calldata signature
    ) public view returns (bool) {
        require(_isApprovedOrOwner(sender, tokenId), "Asset721: transfer caller is not owner nor approved");

        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "safeTransferFromBWO(uint256 from,uint256 to,uint256 tokenId,bytes data,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        from,
                        to,
                        tokenId,
                        keccak256(data),
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

    function _safeTransfer(
        address _msgSender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bool isBWO,
        address sender,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId, isBWO, sender, _getAddressByAccountId(from), _getAddressByAccountId(to));
        require(
            _checkOnERC721Received(_msgSender, _getAddressByAccountId(from), _getAddressByAccountId(to), tokenId, data),
            "Asset721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownersById(tokenId) != 0;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address sender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "Asset721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        uint256 ownerId = ownerAccountOf(tokenId);

        return (sender == owner ||
            _getAccountIdByAddress(sender) == ownerId ||
            isApprovedForAll(owner, sender) ||
            getApproved(tokenId) == sender);
    }

    function safeMint_(
        address _msgSender,
        uint256 to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyShell {
        mint_(_msgSender, to, tokenId);
        require(
            _checkOnERC721Received(_msgSender, address(0), _getAddressByAccountId(to), tokenId, data),
            "Asset721: transfer to non ERC721Receiver implementer"
        );
    }

    function mint_(
        address _msgSender,
        uint256 to,
        uint256 tokenId
    ) public override onlyShell {
        _checkIdIsNotZero(to, "Asset721: mint to the zero id");
        require(!_exists(tokenId), "Asset721: token already minted");

        storageContract.setOwnerById(tokenId, to);
        _setBalanceById(to, _balancesById(to) + 1);

        shell().emitTransfer(address(0), _getAddressByAccountId(to), tokenId);
        shell().emitAssetTransfer(0, to, tokenId, false, _msgSender, getNonce(_msgSender));

        _incrementNonce(_msgSender);
    }

    function burn_(address _msgSender, uint256 tokenId) public override onlyShell {
        _checkSender(_getAccountIdByAddress(ownerOf(tokenId)), _msgSender);
        _burn(tokenId, _msgSender);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, address sender) internal virtual {
        address owner = ownerOf(tokenId);
        // Clear approvals

        _setTokenApprovalById(tokenId, address(0));

        uint256 ownerId = _getAccountIdByAddress(owner);
        _setBalanceById(ownerId, _balancesById(ownerId) -1);
        storageContract.deleteOwnerById(tokenId);

        shell().emitTransfer(_getAddressByAccountId(ownerId), address(0), tokenId);
        shell().emitAssetTransfer(ownerId, 0, tokenId, false, sender, getNonce(sender));

        _incrementNonce(sender);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address _msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Asset721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _checkIdIsNotZero(uint256 _id, string memory _msg) internal pure {
        require(_id != 0, _msg);
    }

    function _checkAddrIsNotZero(address _addr, string memory _msg) internal pure {
        require(_addr != address(0), _msg);
    }

    function _setTokenApprovalById(uint256 tokenId, address to) internal virtual {
        storageContract.setTokenApprovalById(tokenId, to);
    }

    function _setBalanceById(uint256 _id, uint256 _balance) internal {
        storageContract.setBalanceById(_id, _balance);
    }

    function _incrementNonce(address account) internal {
        storageContract.incrementNonce(account);
    }

    function _ownersById(uint256 tokenId) internal view returns (uint256) {
        return storageContract.ownersById(tokenId);
    }

    function _balancesById(uint256 _id) internal view returns (uint256) {
        return storageContract.balancesById(_id);
    }

    function _getAccountIdByAddress(address _address) internal view returns (uint256) {
        return vchain.getAccountIdByAddress(_address);
    }

    function _getOrCreateAccountId(address _address) internal returns (uint256) {
        if (_address == address(0)) {
            return 0;
        } else if (vchain.getAccountIdByAddress(_address) == 0) {
            return vchain.createAccount(_address);
        } else {
            return vchain.getAccountIdByAddress(_address);
        }
    }

    function _getAddressByAccountId(uint256 _id) internal view returns (address) {
        return vchain.getAddressByAccountId(_id);
    }

    function _assetIsEnabled() internal view returns (bool) {
        return vchain.isEnabledAsset(shellContract);
    }

    function _checkSender(uint256 ownerId, address sender) internal view {
        vchain.checkSender(ownerId, sender);
    }

    function _accountIsExist(uint256 _id) internal view returns (bool) {
        return vchain.accountIsExist(_id);
    }

    function _checkBWO(address _sender) internal view {
        require(vchain.checkBWO(_sender), "Asset721: sender is not BWO");
    }

    function _isSafeContract(address _address) internal view returns (bool) {
        return vchain.isSafeContract(_address);
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes calldata signature
    ) internal view {
        require(deadline == 0 || block.timestamp < deadline, "Asset721: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "Asset721: recoverSig failed");
    }
}
