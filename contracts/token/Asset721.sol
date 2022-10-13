//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IAsset721.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IMetaverse.sol";
import "../interfaces/IApplyStorage.sol";
import "../common/Ownable.sol";
import "../storage/Asset721Storage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Asset721 is Context, EIP712, ERC165, IAsset721, IApplyStorage, Ownable {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // tokenURI
    string private _tokenURI;

    IWorld public world;
    IMetaverse public metaverse;
    Asset721Storage public storageContract;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory version_,
        string memory tokenURI_,
        address world_,
        address storage_
    ) EIP712(name_, version_) {
        _name = name_;
        _symbol = symbol_;
        _tokenURI = tokenURI_;
        world = IWorld(world_);
        storageContract = Asset721Storage(storage_);
        metaverse = IMetaverse(world.getMetaverse());
    }

    /**
     * @dev See {IApplyStorage-getStorageAddress}.
     */
    function getStorageAddress() external view override returns (address) {
        return address(storageContract);
    }

    function updateWorld(address _world) public onlyOwner {
        require(address(metaverse) == IWorld(_world).getMetaverse(), "Asset721: metaverse not match");
        world = IWorld(_world);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IAsset-protocol}.
     */
    function protocol() external pure virtual override returns (IAsset.ProtocolEnum) {
        return IAsset.ProtocolEnum.ASSET721;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_tokenURI, tokenId.toString()));
    }

    function setTokenURI(string memory uri) public onlyOwner {
        _tokenURI = uri;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
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
     * @dev See {IAsset721-itemsOf}.
     */
    function itemsOf(
        uint256 owner,
        uint256 startAt,
        uint256 endAt
    ) public view virtual override returns (uint256[] memory) {
        require(startAt <= endAt, "Asset721: startAt must be less than or equal to endAt");
        require(endAt < balanceOf(owner), "Asset721: endAt must be less than the balance of the owner");
        uint256[] memory items = new uint256[](endAt - startAt + 1);
        for (uint256 i = 0; i <= endAt - startAt; i++) {
            items[i] = _ownedTokens(owner, startAt + i);
        }
        return items;
    }

    function _beforeTokenTransfer(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) internal {
        if (from != 0 && from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to != 0 && to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(uint256 to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _setOwnedTokenAndIndex(to, length, tokenId);
    }

    function _removeTokenFromOwnerEnumeration(uint256 from, uint256 tokenId) private {
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = storageContract.ownedTokensIndex(tokenId);

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens(from, lastTokenIndex);
            _setOwnedTokenAndIndex(from, tokenIndex, lastTokenId);
        }

        storageContract.deleteOwnedToken(from, lastTokenIndex);
        storageContract.deleteOwnedTokenIndex(tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     * @dev See {IAsset721-approve}.
     */
    function approve(address spender, uint256 tokenId) public virtual override {
        uint256 ownerId = ownerAccountOf(tokenId);
        require(
            _getAccountIdByAddress(_msgSender()) == ownerId || isApprovedForAll(ownerId, _msgSender()),
            "Asset721: approve caller is not owner nor approved for all"
        );
        _approve(spender, tokenId, false, _msgSender());
    }

    function approveBWO(
        address spender,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        _checkBWOByAsset(_msgSender());
        approveBWOParamsVerify(spender, tokenId, sender, deadline, signature);
        _approve(spender, tokenId, true, sender);
    }

    function approveBWOParamsVerify(
        address spender,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        uint256 ownerId = ownerAccountOf(tokenId);
        require(
            _getAccountIdByAddress(sender) == ownerId || isApprovedForAll(ownerId, sender),
            "Asset721: approve caller is not owner nor approved for all"
        );
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("BWO(address spender,uint256 tokenId,address sender,uint256 nonce,uint256 deadline)"),
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
        require(!_isFreeze(ownerId), "Asset721: approve owner is frozen");
        require(_getOrCreateAccountId(spender) != ownerId, "Asset721: approval to current account");

        _setTokenApprovalById(tokenId, spender);
        emit Approval(ownerOf(tokenId), spender, tokenId);
        emit AssetApproval(ownerId, spender, tokenId, isBWO, sender, getNonce(sender));
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
    function setApprovalForAll(address operator, bool approved) public virtual override {
        uint256 accountId = _getOrCreateAccountId(_msgSender());
        _checkIdIsNotZero(accountId, "Asset721: approveForAll query for nonexistent account");
        _setApprovalForAll(accountId, operator, approved, false, _msgSender());
    }

    function setApprovalForAll(
        uint256 accountId,
        address operator,
        bool approved
    ) public virtual override {
        _checkIdIsNotZero(accountId, "Asset721: approveForAll query for nonexistent account");
        _checkSender(accountId, _msgSender());
        _setApprovalForAll(accountId, operator, approved, false, _msgSender());
    }

    function setApprovalForAllBWO(
        uint256 accountId,
        address operator,
        bool approved,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        _checkBWOByAsset(_msgSender());
        setApprovalForAllBWOParamsVerify(accountId, operator, approved, sender, deadline, signature);
        _setApprovalForAll(accountId, operator, approved, true, sender);
    }

    function setApprovalForAllBWOParamsVerify(
        uint256 accountId,
        address operator,
        bool approved,
        address sender,
        uint256 deadline,
        bytes memory signature
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
                            "BWO(uint256 from,address to,bool approved,address sender,uint256 nonce,uint256 deadline)"
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
        require(!_isFreeze(accountId), "Asset721: approve owner is frozen");
        _checkAddrIsNotZero(operator, "Asset721: approve to the zero address");
        require(_getAccountIdByAddress(operator) != accountId, "Asset721: approval to current account");

        storageContract.setOperatorApprovalById(accountId, operator, approved);
        // emit ERC721 event
        emit ApprovalForAll(sender, operator, approved);
        // emit Asset721 event
        emit AssetApprovalForAll(accountId, operator, approved, isBWO, sender, getNonce(sender));
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
        if (world.isTrust(operator, ownerId)) {
            return true;
        }
        return storageContract.operatorApprovalsById(ownerId, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Asset721: transfer caller is not owner nor approved");
        if (to == address(0)) {
            _burn(tokenId);
        } else {
            _transfer(_getOrCreateAccountId(from), _getOrCreateAccountId(to), tokenId, false, _msgSender(), from, to);
        }
    }

    function transferFrom(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Asset721: transfer caller is not owner nor approved");
        if (toAccount == 0) {
            _burn(tokenId);
        } else {
            _transfer(
                fromAccount,
                toAccount,
                tokenId,
                false,
                _msgSender(),
                _getAddressByAccountId(fromAccount),
                _getAddressByAccountId(toAccount)
            );
        }
    }

    function transferFromBWO(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        _checkBWOByAsset(_msgSender());
        transferFromBWOParamsVerify(fromAccount, toAccount, tokenId, sender, deadline, signature);
        if (toAccount == 0) {
            _burn(tokenId);
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
        bytes memory signature
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
                            "BWO(uint256 from,uint256 to,uint256 tokenId,address sender,uint256 nonce,uint256 deadline)"
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
        require(Asset721.ownerAccountOf(tokenId) == fromAccount, "Asset721: transfer from incorrect owner");
        require(!_isFreeze(fromAccount), "Asset721: transfer from frozen account");
        require(_isExist(toAccount), "Asset721: to account is not exist");
        _checkIdIsNotZero(toAccount, "Asset721: transfer to the zero id");

        _beforeTokenTransfer(fromAccount, toAccount, tokenId);

        // Clear approvals from the previous owner
        _setTokenApprovalById(tokenId, address(0));

        _setBalanceById(fromAccount, _balancesById(fromAccount) - 1);
        _setBalanceById(toAccount, _balancesById(toAccount) + 1);
        storageContract.setOwnerById(tokenId, toAccount);

        emit Transfer(_fromAddr, _toAddr, tokenId);
        emit AssetTransfer(fromAccount, toAccount, tokenId, isBWO, sender, getNonce(sender));

        _incrementNonce(sender);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        safeTransferFrom(_getOrCreateAccountId(from), _getOrCreateAccountId(to), tokenId, data);
    }

    function safeTransferFrom(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Asset721: transfer caller is not owner nor approved");
        if (to == 0) {
            _burn(tokenId);
        } else {
            _safeTransfer(from, to, tokenId, false, _msgSender(), data);
        }
    }

    function safeTransferFromBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        _checkBWOByAsset(_msgSender());
        safeTransferFromBWOParamsVerify(from, to, tokenId, data, sender, deadline, signature);

        if (to == 0) {
            _burn(tokenId);
        } else {
            _safeTransfer(from, to, tokenId, true, sender, data);
        }
    }

    function safeTransferFromBWOParamsVerify(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
        address sender,
        uint256 deadline,
        bytes memory signature
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
                            "BWO(uint256 from,uint256 to,uint256 tokenId,bytes data,address sender,uint256 nonce,uint256 deadline)"
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
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bool isBWO,
        address sender,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId, isBWO, sender, _getAddressByAccountId(from), _getAddressByAccountId(to));
        require(
            _checkOnERC721Received(_getAddressByAccountId(from), _getAddressByAccountId(to), tokenId, data),
            "Asset721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
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

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "Asset721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        _checkAddrIsNotZero(to, "Asset721: mint to the zero address");
        _mint(_getOrCreateAccountId(to), tokenId);
    }

    function _mint(uint256 to, uint256 tokenId) internal virtual {
        _checkIdIsNotZero(to, "Asset721: transfer to the zero id");
        require(!_exists(tokenId), "Asset721: token already minted");
        _beforeTokenTransfer(0, to, tokenId);

        storageContract.setOwnerById(tokenId, to);
        _setBalanceById(to, _balancesById(to) + 1);

        emit Transfer(address(0), _getAddressByAccountId(to), tokenId);
        emit AssetTransfer(0, to, tokenId, false, _msgSender(), getNonce(_msgSender()));

        _incrementNonce(_msgSender());
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = Asset721.ownerOf(tokenId);
        // Clear approvals

        _setTokenApprovalById(tokenId, address(0));

        uint256 ownerId = _getAccountIdByAddress(owner);
        _beforeTokenTransfer(ownerId, 0, tokenId);
        _setBalanceById(ownerId, 1);
        storageContract.deleteOwnerById(tokenId);

        emit Transfer(_getAddressByAccountId(ownerId), address(0), tokenId);
        emit AssetTransfer(ownerId, 0, tokenId, false, _msgSender(), getNonce(_msgSender()));

        _incrementNonce(_msgSender());
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
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
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

    function getNonce(address account) public view virtual override returns (uint256) {
        return storageContract.nonces(account);
    }

    function worldAddress() external view virtual override returns (address) {
        return address(world);
    }

    function _setTokenApprovalById(uint256 tokenId, address to) internal virtual {
        storageContract.setTokenApprovalById(tokenId, to);
    }

    function _setBalanceById(uint256 _id, uint256 _balance) internal {
        storageContract.setBalanceById(_id, _balance);
    }

    function _ownedTokens(uint256 id, uint256 index) internal view returns (uint256) {
        return storageContract.ownedTokens(id, index);
    }

    function _setOwnedTokenAndIndex(
        uint256 to,
        uint256 length,
        uint256 tokenId
    ) internal {
        storageContract.setOwnedToken(to, length, tokenId);
        storageContract.setOwnedTokenIndex(tokenId, length);
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
        return metaverse.getAccountIdByAddress(_address);
    }

    function _getOrCreateAccountId(address _address) internal returns (uint256) {
        return metaverse.getOrCreateAccountId(_address);
    }

    function _getAddressByAccountId(uint256 _id) internal view returns (address) {
        return metaverse.getAddressByAccountId(_id);
    }

    function _isFreeze(uint256 _id) internal view returns (bool) {
        return metaverse.isFreeze(_id);
    }

    function _checkSender(uint256 ownerId, address sender) internal view {
        metaverse.checkSender(ownerId, sender);
    }

    function _isExist(uint256 _id) internal view returns (bool) {
        return metaverse.accountIsExist(_id);
    }

    function _checkBWOByAsset(address _sender) internal view {
        world.checkBWOByAsset(_sender);
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "Asset721: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "Asset721: recoverSig failed");
    }
}
