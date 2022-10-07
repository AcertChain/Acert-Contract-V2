//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IAsset721.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IMetaverse.sol";
import "../common/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Asset721 is EIP712, ERC165, IAsset721, Ownable {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // world addr
    address private _world;
    // metadverse addr
    address private _metadverse;
    // tokenURI
    string private _tokenURI;

    IWorld public world;
    IMetaverse public metaverse;

    // nonce
    mapping(address => uint256) public _nonces;

    // Mapping from token ID to owner address
    mapping(uint256 => uint256) private _ownersById;

    // Mapping owner address to token count
    mapping(uint256 => uint256) private _balancesById;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovalsById;

    // Mapping from owner to operator approvals
    mapping(uint256 => mapping(address => bool)) private _operatorApprovalsById;

    // Mapping from owner to list of owned token IDs
    mapping(uint256 => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory version_,
        string memory tokenURI_,
        address world_
    ) EIP712(name_, version_) {
        _name = name_;
        _symbol = symbol_;
        _tokenURI = tokenURI_;
        _world = world_;
        world = IWorld(world_);
        _metadverse = world.getMetaverse();
        metaverse = IMetaverse(_metadverse);
    }

    function updateWorld(address world) public onlyOwner {
        require(
            _metadverse == IWorld(world).getMetaverse(),
            "Item: metaverse not match"
        );
        _world = world;
        world = IWorld(_address);
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
    function protocol()
        external
        pure
        virtual
        returns (IWorldAsset.ProtocolEnum)
    {
        return IWorldAsset.ProtocolEnum.ASSET721;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_tokenURI, tokenId.toString()));
    }

    function setTokenURI(string memory uri) public onlyOwner {
        _tokenURI = uri;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        _checkAddrIsNotZero(owner, "Item: address zero is not a valid owner");
        return _balancesById[metaverse.getAccountIdByAddress(owner)];
    }

    /**
     * @dev See {IAsset721-balanceOf}.
     */
    function balanceOf(uint256 accountId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        _checkIdIsNotZero(accountId, "Item: id zero is not a valid owner");
        return _balancesById[accountId];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address owner)
    {
        owner = metaverse.getAddressByAccountId(_ownersById[tokenId]);
        _checkAddrIsNotZero(owner, "Item: owner query for nonexistent token");
    }

    /**
     * @dev See {IAsset721-ownerAccountOf}.
     */
    function ownerAccountOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256 ownerId)
    {
        ownerId = _ownersById[tokenId];
        _checkIdIsNotZero(ownerId, "Item: owner query for nonexistent token");
    }

    /**
     * @dev See {IAsset721-itemsOf}.
     */
    function itemsOf(
        uint256 owner,
        uint256 startAt,
        uint256 endAt
    ) public view virtual override returns (uint256[] memory) {
        require(
            startAt <= endAt,
            "Item: startAt must be less than or equal to endAt"
        );
        require(
            endAt < balanceOfItem(owner),
            "Item: endAt must be less than the balance of the owner"
        );
        uint256[] memory items = new uint256[](endAt - startAt + 1);
        for (uint256 i = 0; i <= endAt - startAt; i++) {
            items[i] = _ownedTokens[owner][startAt + i];
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
        uint256 length = balanceOfItem(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _removeTokenFromOwnerEnumeration(uint256 from, uint256 tokenId)
        private
    {
        uint256 lastTokenIndex = balanceOfItem(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev See {IERC721-approve}.
     * @dev See {IAsset721-approve}.
     */
    function approve(address spender, uint256 tokenId) public virtual override {
        uint256 ownerId = ownerAccountOf(tokenId);
        require(
            metaverse.getAccountIdByAddress(_msgSender()) == ownerId || isApprovedForAll(ownerId, msg.sender),
            "Item: approve caller is not owner nor approved for all"
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
        world.checkBWOByAsset(_msgSender());
        approveBWOParamsVerify(spender, tokenId, sender, deadline, signature);
        _approve(to, tokenId, true, sender);
    }

    function approveBWOParamsVerify(
        address spender,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        uint256 ownerId = ownerAccountOf(tokenId);
        checkSender(ownerId, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(address sender,uint256 tokenId,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        sender,
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

    function _approve(address spender, uint256 tokenId, bool isBWO, address sender) internal virtual {
        uint256 ownerId = ownerAccountOf(tokenId);
        require(!metaverse.isFreeze(ownerId), "Asset20: approve owner is frozen");
        _checkAddrIsNotZero(spender, "Asset721: approve to the zero address");
        uint265 spenderId = metaverse.getAccountIdByAddress(spender);
        require(spenderId != ownerId, "Asset721: approval to current account");
        _tokenApprovalsById[tokenId] = spender;
        emit Approval(sender, spender, tokenId);
        emit ApprovalItem(ownerId, spender, tokenId, isBWO, sender, getNonce(sender));
        _nonces[sender] += 1;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_exists(tokenId), "Asset721: approved query for nonexistent token");
        return _tokenApprovalsById[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        uint256 accountId = metaverse.getAccountIdByAddress(_msgSender());
        _checkIdIsNotZero(accountId, "Asset721: approveForAll query for nonexistent account");
        _setApprovalForAll(accountId, operator, approved, false, _msgSender());
    }

    function setApprovalForAll(
        uint256 accountId,
        address operator,
        bool approved
    ) public virtual override {
        _checkIdIsNotZero(accountId, "Asset721: approveForAll query for nonexistent account");
        metaverse.checkSender(accountId, _msgSender());
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
        world.checkBWOByAsset(_msgSender());
        setApprovalForAllBWOParamsVerify(
            accountId,
            operator,
            approved,
            sender,
            deadline,
            signature
        );
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
        checkSender(accountId, sender);
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
        require(!metaverse.isFreeze(accountId), "Asset721: approve owner is frozen");
        _checkAddrIsNotZero(operator, "Asset721: approve to the zero address");
        uint265 spenderId = metaverse.getAccountIdByAddress(spender);
        require(spenderId != accountId, "Asset721: approval to current account");
        _operatorApprovalsById[accountId][operator] = approved;
        // emit ERC721 event
        emit ApprovalForAll(sender, operator, approved);
        // emit Asset721 event
        emit ApprovalForAll(accountId, operator, approved, isBWO, sender, getNonce(sender));
        _nonces[sender] += 1;
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        uint256 ownerId = metaverse.getAccountIdByAddress(owner);
        return isApprovedForAll(ownerId, operator);
    }

    function isApprovedForAll(uint256 ownerId, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        _checkIdIsNotZero(ownerId, "Asset721: id zero is not a valid owner");
        if (world.isTrust(operator, ownerId)) {
            return true;
        }
        return _operatorApprovalsById[ownerId][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Item: transfer caller is not owner nor approved"
        );
        if (to == address(0)) {
            _burn(tokenId);
        } else {
            _transfer(metaverse.getAccountIdByAddress(from), metaverse.getOrCreateAccountId(to), amount, false, sender, from, to);
        }
    }

    function transferFromItem(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Item: transfer caller is not owner nor approved"
        );
        _transfer(fromAccount, toAccount, tokenId, false, _msgSender(), metaverse.getAddressByAccountId(fromAccount), metaverse.getAddressByAccountId(toAccount));
    }

    function transferFromBWO(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        world.checkBWOByAsset(_msgSender());
        transferFromItemBWOParamsVerify(
            fromAccount,
            toAccount,
            tokenId,
            sender,
            deadline,
            signature
        );
        _transfer(fromAccount, toAccount, tokenId, true, sender, metaverse.getAddressByAccountId(fromAccount), metaverse.getAddressByAccountId(toAccount));
    }

    function transferFromBWOParamsVerify(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        metaverse.checkSender(fromAccount, sender);
        uint256 nonce = getNonce(sender);
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 fromAccount,uint256 toAccount,uint256 tokenId,address sender,uint256 nonce,uint256 deadline)"
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
        require(
            Item721.ownerOfItem(tokenId) == fromAccount,
            "Item: transfer from incorrect owner"
        );
        require(!metaverse.isFreeze(fromAccount), "Asset721: transfer from frozen account");
        require(metaverse.accountIsExist(toAccount), "Asset721: to account is not exist");
        _checkIdIsNotZero(toAccount, "Item: transfer to the zero id");
        metaverse.accountIsExist(toAccount);

        _beforeTokenTransfer(fromAccount, toAccount, tokenId);

        // Clear approvals from the previous owner
        _tokenApprovalsById[tokenId] = address(0);

        _balancesById[fromAccount] -= 1;
        _balancesById[toAccount] += 1;
        _ownersById[tokenId] = toAccount;

        emit Transfer(_fromAddr, toAccount, tokenId);
        emit Transfer(fromAccount, toAccount, tokenId, isBWO, sender, getNonce(sender));
        _nonces[sender] += 1;
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
        _checkAddrIsNotZero(to, "Item: transfer to the zero address");
        safeTransferFrom(
            metaverse.getAccountIdByAddress(from),
            metaverse.getOrCreateAccountId(to),
            tokenId,
            data
        );
    }

    function safeTransferFrom(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Item: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFromItemBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        safeTransferFromItemBWOParamsVerify(
            from,
            to,
            tokenId,
            data,
            sender,
            deadline,
            signature
        );
        _safeTransfer(from, to, tokenId, data);
        emit TransferItemBWO(from, to, tokenId, sender, getNonce(sender));
        _nonces[sender] += 1;
    }

    function safeTransferFromItemBWOParamsVerify(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        _isBWO(msg.sender);
        _checkAddressProxy(sender, from);
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(
                metaverse.getAddressByAccountId(from),
                metaverse.getAddressByAccountId(to),
                tokenId,
                data
            ),
            "Item: transfer to non ERC721Receiver implementer"
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
        return _ownersById[tokenId] != 0;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address sender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), "Item: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        address ownerId = ownerAccountOf(tokenId);

        return (sender == owner ||
            metaverse.getAccountIdByAddress(sender) == ownerId ||
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
            "Item: transfer to non ERC721Receiver implementer"
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
        _checkAddrIsNotZero(to, "Item: mint to the zero address");
        _mint(metaverse.getOrCreateAccountId(to), tokenId);
    }

    function _mint(uint256 to, uint256 tokenId) internal virtual {
        _checkIdIsNotZero(to, "Item: transfer to the zero id");
        require(!_exists(tokenId), "Item: token already minted");
        _beforeTokenTransfer(0, to, tokenId);
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;
        emit Transfer(address(0), metaverse.getAddressByAccountId(to), tokenId);
        emit Transfer(0, to, tokenId, false, _msgSender(), getNonce(_msgSender()));
        _nonces[_msgSender()] += 1;
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
        address owner = Item721.ownerOf(tokenId);
        // Clear approvals
        _tokenApprovalsById[tokenId] = address(0);
        
        uint256 ownerId = metaverse.getAccountIdByAddress(owner);
        _beforeTokenTransfer(ownerId, 0, tokenId);
        _balancesById[ownerId] -= 1;
        delete _ownersById[tokenId];

        emit Transfer(metaverse.getAddressByAccountId(owner), address(0), tokenId);
        emit Transfer(ownerId, 0, tokenId, false, _msgSender(), getNonce(_msgSender()));
        _nonces[_msgSender()] += 1;
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
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Item: transfer to non ERC721Receiver implementer");
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

    function _checkAddrIsNotZero(address _addr, string memory _msg)
        internal
        pure
    {
        require(_addr != address(0), _msg);
    }

    function getNonce(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _nonces[account];
    }

    function worldAddress() external view virtual override returns (address) {
        return _world;
    }

    function protocol()
        external
        pure
        virtual
        returns (IWorldAsset.ProtocolEnum)
    {
        return IWorldAsset.ProtocolEnum.ITEM721;
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "Item: BWO call expired");
        require(
            signer == ECDSA.recover(digest, signature),
            "Item: recoverSig failed"
        );
    }
}
