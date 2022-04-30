//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IItem721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Item721 is Context, EIP712, ERC165, IItem721 {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // world addr
    address private _world;
    // owner addr
    address private _owner;

    IWorld _iWorld;

    // nonce
    mapping(uint256 => uint256) private _nonces;

    // Mapping from token ID to owner address
    mapping(uint256 => uint256) private _ownersById;

    // Mapping owner address to token count
    mapping(uint256 => uint256) private _balancesById;

    // Mapping from token ID to approved address
    mapping(uint256 => uint256) private _tokenApprovalsById;

    // Mapping from owner to operator approvals
    mapping(uint256 => mapping(uint256 => bool)) private _operatorApprovalsById;

    mapping(address => uint256) private _AddressesToIds;

    mapping(uint256 => address) private _IdsToAddresses;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory version_,
        address world_
    ) EIP712(name_, version_) {
        _name = name_;
        _symbol = symbol_;
        _world = world_;
        _owner = _msgSender();
        _iWorld = IWorld(_world);
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
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IItem721).interfaceId ||
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
        require(
            owner != address(0),
            "Item721: address zero is not a valid owner"
        );

        return _balancesById[_AddressesToIds[owner]];
    }

    /**
     * @dev See {IItem721-balanceOfById}.
     */
    function balanceOfById(uint256 ownerId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(ownerId != 0, "Item721: id zero is not a valid owner");
        return _balancesById[ownerId];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        uint256 ownerId = _ownersById[tokenId];
        address owner = _IdsToAddresses[ownerId];
        require(
            owner != address(0),
            "Item721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IItem721-ownerOfById}.
     */
    function ownerOfById(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 owner = _ownersById[tokenId];
        require(owner != 0, "Item721: owner query for nonexistent token");
        return owner;
    }

    function getNonce(uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _nonces[id];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IItem721-worldAddress}.
     */
    function worldAddress() external view returns (address) {
        return _world;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = Item721.ownerOf(tokenId);
        require(to != owner, "Item721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Item721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IItem721-approveById}.
     */
    function approveById(uint256 to, uint256 tokenId) public virtual override {
        uint256 owner = Item721.ownerOfById(tokenId);
        require(to != owner, "Item721: approval to current owner");

        uint256 senderId = _getIdByAddress(_msgSender());

        require(
            senderId == owner || isApprovedForAllById(owner, senderId),
            "Item721: approve caller is not owner nor approved for all"
        );

        _approveById(to, tokenId, false);
    }

    function approveByBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        // todo: check BWO
        require(_world != _msgSender(), "Item: must be the world");

        uint256[] memory digest = new uint256[](5);
        digest[0] = from;
        digest[1] = to;
        digest[2] = tokenId;
        digest[3] = _nonces[from];
        digest[4] = deadline;

        address fromAddr = _getAddressById(from);
        require(
            fromAddr != _recoverSig(_hashArgs(digest), signature),
            "approveByBWO : recoverSig failed"
        );

        require(
            block.timestamp < deadline,
            "approveByBWO: signed transaction expired"
        );
        _nonces[from]++;

        uint256 owner = Item721.ownerOfById(tokenId);
        require(to != owner, "Item721: approval to current owner");

        require(
            from == owner || isApprovedForAllById(owner, from),
            "Item721: approve caller is not owner nor approved for all"
        );

        _approveById(to, tokenId, true);
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
        require(
            _exists(tokenId),
            "Item721: approved query for nonexistent token"
        );
        return _IdsToAddresses[_tokenApprovalsById[tokenId]];
    }

    function getApprovedById(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            _exists(tokenId),
            "Item721: approved query for nonexistent token"
        );
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
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function setApprovalForAllById(uint256 operator, bool approved)
        public
        virtual
        override
    {
        uint256 senderId = _getIdByAddress(_msgSender());
        _setApprovalForAllById(senderId, operator, approved, false);
    }

    function setApprovalForAllByBWO(
        uint256 sender,
        uint256 operator,
        bool approved,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        // todo: check BWO
        require(_world != _msgSender(), "Item: must be the world");
        uint256[] memory digest = new uint256[](4);
        digest[0] = sender;
        digest[1] = operator;
        digest[2] = _nonces[sender];
        digest[3] = deadline;
        address fromAddr = _getAddressById(sender);
        require(
            fromAddr != _recoverSig(_hashArgs(digest, approved), signature),
            "approveByBWO : recoverSig failed"
        );
        require(
            block.timestamp < deadline,
            "approveByBWO: signed transaction expired"
        );
        _nonces[sender]++;
        _setApprovalForAllById(sender, operator, approved, true);
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
        uint256 ownerId = _AddressesToIds[owner];
        uint256 operatorId = _AddressesToIds[operator];
        return _operatorApprovalsById[ownerId][operatorId];
    }

    function isApprovedForAllById(uint256 owner, uint256 operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovalsById[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        uint256 fromId = _getIdByAddress(from);
        if (_isTrust(_msgSender(), fromId)) {
            _transfer(from, to, tokenId);
        }

        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Item721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function transferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        if (_isTrust(_msgSender(), from)) {
            _transferById(from, to, tokenId, false);
        }
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Item721: transfer caller is not owner nor approved"
        );

        _transferById(from, to, tokenId, false);
    }

    function transferFromByBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        // todo: check BWO
        require(_world != _msgSender(), "Item: must be the world");

        uint256[] memory digest = new uint256[](6);
        digest[0] = sender;
        digest[1] = from;
        digest[2] = to;
        digest[3] = tokenId;
        digest[4] = _nonces[from];
        digest[5] = deadline;

        address senderAddr = _getAddressById(sender);
        require(
            senderAddr != _recoverSig(_hashArgs(digest), signature),
            "approveByBWO : recoverSig failed"
        );

        require(
            block.timestamp < deadline,
            "approveByBWO: signed transaction expired"
        );
        _nonces[from]++;

        require(
            _isApprovedOrOwner(senderAddr, tokenId),
            "Item721: transfer caller is not owner nor approved"
        );

        _transferById(from, to, tokenId, true);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFromById(from, to, tokenId, "");
    }

    function safeTransferFromByBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        // todo: check BWO
        require(_world != _msgSender(), "Item: must be the world");

        uint256[] memory digest = new uint256[](5);
        digest[0] = from;
        digest[1] = to;
        digest[2] = tokenId;
        digest[3] = _nonces[from];
        digest[4] = deadline;

        address fromAddr = _getAddressById(from);
        require(
            fromAddr != _recoverSig(_hashArgs(digest), signature),
            "approveByBWO : recoverSig failed"
        );

        require(
            block.timestamp < deadline,
            "approveByBWO: signed transaction expired"
        );
        _nonces[from]++;

        safeTransferFromById(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Item721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function safeTransferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Item721: transfer caller is not owner nor approved"
        );
        _safeTransferById(from, to, tokenId, _data);
    }

    function safeTransferFromByBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata data,
        bytes memory signature
    ) public virtual override {
        // todo: check BWO
        require(_world != _msgSender(), "Item: must be the world");

        uint256[] memory digest = new uint256[](6);
        digest[0] = sender;
        digest[1] = from;
        digest[2] = to;
        digest[3] = tokenId;
        digest[4] = _nonces[from];
        digest[5] = deadline;

        address senderAddr = _getAddressById(sender);
        require(
            senderAddr != _recoverSig(_hashArgs(digest, data), signature),
            "approveByBWO : recoverSig failed"
        );

        require(
            block.timestamp < deadline,
            "approveByBWO: signed transaction expired"
        );
        _nonces[from]++;

        require(
            _isApprovedOrOwner(senderAddr, tokenId),
            "Item721: transfer caller is not owner nor approved"
        );
        _safeTransferById(from, to, tokenId, data);
    }

    function changeAccountAddress(uint256 id, address newAddr)
        public
        virtual
        override
        returns (bool)
    {
        require(_world != _msgSender(), "Cash: must be the world");
        address oldAddr = _IdsToAddresses[id];
        _IdsToAddresses[id] = newAddr;
        _AddressesToIds[newAddr] = id;
        delete _AddressesToIds[oldAddr];
        return true;
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "Item721: transfer to non ERC721Receiver implementer"
        );
    }

    function _safeTransferById(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transferById(from, to, tokenId, false);

        address fromAddr = _getAddressById(from);
        address toAddr = _getAddressById(to);

        require(
            _checkOnERC721Received(fromAddr, toAddr, tokenId, _data),
            "Item721: transfer to non ERC721Receiver implementer"
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "Item721: operator query for nonexistent token"
        );
        address owner = Item721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _isApprovedOrOwnerById(uint256 spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "Item721: operator query for nonexistent token"
        );
        uint256 owner = Item721.ownerOfById(tokenId);
        return (spender == owner ||
            isApprovedForAllById(owner, spender) ||
            getApprovedById(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "Item721: transfer to non ERC721Receiver implementer"
        );
    }

    function mint(address to, uint256 tokenId) public {
        require(_owner == _msgSender(), "Item721: must be owner to mint");
        _mint(to, tokenId);
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
        require(to != address(0), "Item721: mint to the zero address");
        require(!_exists(tokenId), "Item721: token already minted");

        uint256 toId = _getIdByAddress(to);

        _balancesById[toId] += 1;
        _ownersById[tokenId] = toId;

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(_owner == _msgSender(), "Item721: must be owner to burn");
        _burn(tokenId);
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
        _approve(address(0), tokenId);

        uint256 ownerId = _getIdByAddress(owner);

        _balancesById[ownerId] -= 1;
        delete _ownersById[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            Item721.ownerOf(tokenId) == from,
            "Item721: transfer from incorrect owner"
        );
        require(to != address(0), "Item721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint256 fromId = _getIdByAddress(from);
        uint256 toId = _getIdByAddress(to);

        _balancesById[fromId] -= 1;
        _balancesById[toId] += 1;
        _ownersById[tokenId] = toId;

        emit Transfer(from, to, tokenId);
    }

    function _transferById(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bool isBWO
    ) internal virtual {
        require(
            Item721.ownerOfById(tokenId) == from,
            "Item721: transfer from incorrect owner"
        );
        require(to != 0, "Item721: transfer to the zero");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balancesById[from] -= 1;
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;

        if (isBWO) {
            emit TransferByBWO(from, to, tokenId);
        } else {
            emit TransferById(from, to, tokenId);
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        uint256 toId = _getIdByAddress(to);
        _tokenApprovalsById[tokenId] = toId;
        emit Approval(Item721.ownerOf(tokenId), to, tokenId);
    }

    function _approveById(
        uint256 to,
        uint256 tokenId,
        bool isBWO
    ) internal virtual {
        _tokenApprovalsById[tokenId] = to;
        if (isBWO) {
            emit ApprovalByBWO(Item721.ownerOfById(tokenId), to, tokenId);
        } else {
            emit ApprovalById(Item721.ownerOfById(tokenId), to, tokenId);
        }
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "Item721: approve to caller");
        uint256 ownerId = _getIdByAddress(owner);
        uint256 operatorId = _getIdByAddress(operator);
        _operatorApprovalsById[ownerId][operatorId] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _setApprovalForAllById(
        uint256 owner,
        uint256 operator,
        bool approved,
        bool isBWO
    ) internal virtual {
        require(owner != operator, "Item721: approve to caller");
        _operatorApprovalsById[owner][operator] = approved;

        if (isBWO) {
            emit ApprovalForAllByBWO(owner, operator, approved);
        } else {
            emit ApprovalForAllById(owner, operator, approved);
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "Item721: transfer to non ERC721Receiver implementer"
                    );
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

    function _getIdByAddress(address addr) internal returns (uint256) {
        uint256 id;
        if (_AddressesToIds[addr] == 0) {
            id = _iWorld.getOrCreateAccountId(addr);
            _AddressesToIds[addr] = id;
            _IdsToAddresses[id] = addr;
        }
        return _AddressesToIds[addr];
    }

    function _getAddressById(uint256 id) internal returns (address) {
        address addr;
        if (_IdsToAddresses[id] == address(0)) {
            addr = _iWorld.getAddressById(id);
            _AddressesToIds[addr] = id;
            _IdsToAddresses[id] = addr;
        }
        return _IdsToAddresses[id];
    }

    function _isTrust(address _contract, uint256 _id)
        internal
        view
        returns (bool)
    {
        return _iWorld.isTrust(_contract, _id);
    }

    function _recoverSig(bytes32 digest, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(digest, signature);
    }

    function _hashArgs(uint256[] memory args)
        internal
        view
        returns (bytes32 hash)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(keccak256("MyFunction(uint256[] args)"), args))
        );
        return digest;
    }

    function _hashArgs(uint256[] memory args, bytes memory data)
        internal
        view
        returns (bytes32 hash)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("MyFunction(uint256[] args,bytes data)"),
                    args,
                    data
                )
            )
        );
        return digest;
    }

    function _hashArgs(uint256[] memory args, bool flag)
        internal
        view
        returns (bytes32 hash)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("MyFunction(uint256[] args,bool flag)"),
                    args,
                    flag
                )
            )
        );
        return digest;
    }
}
