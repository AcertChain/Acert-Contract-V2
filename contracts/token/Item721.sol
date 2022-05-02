//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IItem721.sol";
import "../interfaces/IAsset.sol";
import "../interfaces/IItem721Bwo.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
I01:must be the BWO
I02:recoverSig failed
I03:BWO call expired
I04:approval to current owner
I05:approve caller is not owner nor approved for all
 */

contract Item721 is EIP712, ERC165, IItem721 {
    using Address for address;

    enum TypeOperation {
        ADDRESS,
        ID,
        BWO
    }
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
        _owner = msg.sender;
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
            // interfaceId == type(IItem721).interfaceId ||
            // interfaceId == type(IItem721Bwo).interfaceId ||
            // interfaceId == type(IAsset).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        _safeMint(to, tokenId, _data);
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
        require(owner != address(0), "Item: address zero is not a valid owner");
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
        require(ownerId != 0, "Item: id zero is not a valid owner");
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
        address owner = _IdsToAddresses[_ownersById[tokenId]];
        require(owner != address(0), "Item: owner query for nonexistent token");
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
        require(owner != 0, "Item: owner query for nonexistent token");
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
    function worldAddress() external view virtual override returns (address) {
        return _world;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {}

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = Item721.ownerOf(tokenId);
        require(to != owner, "Item: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Item: approve caller is not owner nor approved for all"
        );
        _approve(_getIdByAddress(to), tokenId, TypeOperation.ADDRESS);
    }

    /**
     * @dev See {IItem721-approveById}.
     */
    function approveById(uint256 to, uint256 tokenId) public virtual override {
        uint256 owner = Item721.ownerOfById(tokenId);
        require(to != owner, "Item: approval to current owner");

        uint256 senderId = _getIdByAddress(msg.sender);
        require(
            senderId == owner || isApprovedForAllById(owner, senderId),
            "Item: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId, TypeOperation.ID);
    }

    function approveByBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        // todo: check BWO
        require(_world != msg.sender, "I01");

        uint256[] memory digest = new uint256[](5);
        digest[0] = from;
        digest[1] = to;
        digest[2] = tokenId;
        digest[3] = _nonces[from];
        digest[4] = deadline;

        _recoverSig(
            deadline,
            _getAddressById(from),
            _hashArgs(digest),
            signature
        );

        uint256 owner = Item721.ownerOfById(tokenId);
        require(to != owner, "I04");

        require(from == owner || isApprovedForAllById(owner, from), "I05");

        _nonces[from]++;

        _approve(to, tokenId, TypeOperation.BWO);
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
        require(_exists(tokenId), "Item: approved query for nonexistent token");
        return _IdsToAddresses[_tokenApprovalsById[tokenId]];
    }

    function getApprovedById(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(_exists(tokenId), "Item: approved query for nonexistent token");
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
        require(msg.sender != operator, "Item: approve to caller");
        _operatorApprovalsById[_getIdByAddress(msg.sender)][
            _getIdByAddress(operator)
        ] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function setApprovalForAllById(uint256 operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAllById(
            _getIdByAddress(msg.sender),
            operator,
            approved,
            false
        );
    }

    function setApprovalForAllByBWO(
        uint256 sender,
        uint256 operator,
        bool approved,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        // todo: check BWO
        require(_world != msg.sender, "I01");
        uint256[] memory digest = new uint256[](4);
        digest[0] = sender;
        digest[1] = operator;
        digest[2] = _nonces[sender];
        digest[3] = deadline;
        _recoverSig(
            deadline,
            _getAddressById(sender),
            _hashArgs(digest, approved),
            signature
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
        return
            _operatorApprovalsById[_AddressesToIds[owner]][
                _AddressesToIds[operator]
            ];
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
        require(to != address(0), "Item: transfer to the zero address");
        uint256 fromId = _getIdByAddress(from);
        uint256 toId = _getIdByAddress(to);
        if (_iWorld.isTrust(msg.sender, fromId)) {
            _transfer(fromId, toId, tokenId, TypeOperation.ADDRESS);
        }

        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Item: transfer caller is not owner nor approved"
        );

        _transfer(fromId, toId, tokenId, TypeOperation.ADDRESS);
    }

    function transferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        if (_iWorld.isTrust(msg.sender, from)) {
            _transfer(from, to, tokenId, TypeOperation.ID);
        }
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Item: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId, TypeOperation.ID);
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
        require(_world != msg.sender, "I01");

        uint256[] memory digest = new uint256[](6);
        digest[0] = sender;
        digest[1] = from;
        digest[2] = to;
        digest[3] = tokenId;
        digest[4] = _nonces[from];
        digest[5] = deadline;

        address senderAddr = _getAddressById(sender);
        _recoverSig(deadline, senderAddr, _hashArgs(digest), signature);

        require(_isApprovedOrOwner(senderAddr, tokenId), "I04");
        _nonces[from]++;
        _transfer(from, to, tokenId, TypeOperation.BWO);
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
        require(_world != msg.sender, "I01");

        uint256[] memory digest = new uint256[](5);
        digest[0] = from;
        digest[1] = to;
        digest[2] = tokenId;
        digest[3] = _nonces[from];
        digest[4] = deadline;

        _recoverSig(
            deadline,
            _getAddressById(from),
            _hashArgs(digest),
            signature
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
            _isApprovedOrOwner(msg.sender, tokenId),
            "Item: transfer caller is not owner nor approved"
        );
        require(to != address(0), "Item: transfer to the zero address");
        _safeTransfer(
            _getIdByAddress(from),
            _getIdByAddress(to),
            tokenId,
            _data,
            TypeOperation.ADDRESS
        );
    }

    function safeTransferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Item: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data, TypeOperation.ID);
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
        require(_world != msg.sender, "I01");

        uint256[] memory digest = new uint256[](6);
        digest[0] = sender;
        digest[1] = from;
        digest[2] = to;
        digest[3] = tokenId;
        digest[4] = _nonces[from];
        digest[5] = deadline;

        address senderAddr = _getAddressById(sender);
        _recoverSig(deadline, senderAddr, _hashArgs(digest, data), signature);

        _nonces[from]++;

        require(_isApprovedOrOwner(senderAddr, tokenId), "I05");
        _safeTransfer(from, to, tokenId, data, TypeOperation.BWO);
    }

    function changeAccountAddress(uint256 id, address newAddr)
        public
        virtual
        override
        returns (bool)
    {
        require(_world != msg.sender, "must be the world");
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
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data,
        TypeOperation op
    ) internal virtual {
        _transfer(from, to, tokenId, op);
        address fromAddr = _getAddressById(from);
        address toAddr = _getAddressById(to);
        require(
            _checkOnERC721Received(fromAddr, toAddr, tokenId, _data),
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), "Item: operator query for nonexistent token");
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
        require(_exists(tokenId), "Item: operator query for nonexistent token");
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
            "Item: transfer to non ERC721Receiver implementer"
        );
    }

    function mint(address to, uint256 tokenId) public {
        require(_owner == msg.sender, "must be owner to mint");
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
        require(to != address(0), "Item: mint to the zero address");
        require(!_exists(tokenId), "Item: token already minted");

        uint256 toId = _getIdByAddress(to);

        _balancesById[toId] += 1;
        _ownersById[tokenId] = toId;

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(_owner == msg.sender, "Item: must be owner to burn");
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
        _approve(0, tokenId, TypeOperation.ADDRESS);

        uint256 ownerId = _getIdByAddress(owner);

        _balancesById[ownerId] -= 1;
        delete _ownersById[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        TypeOperation operation
    ) internal virtual {
        require(
            Item721.ownerOfById(tokenId) == from,
            "Item: transfer from incorrect owner"
        );
        require(to != 0, "Item: transfer to the zero address or zero id");

        // Clear approvals from the previous owner
        _approve(0, tokenId, operation);

        _balancesById[from] -= 1;
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;

        if (operation == TypeOperation.BWO) {
            emit TransferByBWO(from, to, tokenId);
        } else if (operation == TypeOperation.ID) {
            emit TransferById(from, to, tokenId);
        } else if (operation == TypeOperation.ADDRESS) {
            emit Transfer(_getAddressById(from), _getAddressById(to), tokenId);
        }
    }

    function _approve(
        uint256 to,
        uint256 tokenId,
        TypeOperation typeOperation
    ) internal virtual {
        _tokenApprovalsById[tokenId] = to;
        if (typeOperation == TypeOperation.BWO) {
            emit ApprovalByBWO(Item721.ownerOfById(tokenId), to, tokenId);
        } else if (typeOperation == TypeOperation.ID) {
            emit ApprovalById(Item721.ownerOfById(tokenId), to, tokenId);
        } else {
            emit Approval(
                Item721.ownerOf(tokenId),
                _getAddressById(to),
                tokenId
            );
        }
    }

    function _setApprovalForAllById(
        uint256 owner,
        uint256 operator,
        bool approved,
        bool isBWO
    ) internal virtual {
        require(owner != operator, "Item: approve to caller");
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
        if (to.code.length > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
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

    function _getIdByAddress(address addr) internal returns (uint256) {
        if (_AddressesToIds[addr] == 0) {
            uint256 id = _iWorld.getOrCreateAccountId(addr);
            _AddressesToIds[addr] = id;
            _IdsToAddresses[id] = addr;
        }
        return _AddressesToIds[addr];
    }

    function _getAddressById(uint256 id) internal returns (address) {
        if (_IdsToAddresses[id] == address(0)) {
            address addr = _iWorld.getAddressById(id);
            _AddressesToIds[addr] = id;
            _IdsToAddresses[id] = addr;
        }
        return _IdsToAddresses[id];
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "I03");
        require(signer != ECDSA.recover(digest, signature), "I02");
    }

    function _hashArgs(uint256[] memory args) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(keccak256("MyFunction(uint256[] args)"), args)
                )
            );
    }

    function _hashArgs(uint256[] memory args, bytes memory data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("MyFunction(uint256[] args,bytes data)"),
                        args,
                        data
                    )
                )
            );
    }

    function _hashArgs(uint256[] memory args, bool flag)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("MyFunction(uint256[] args,bool flag)"),
                        args,
                        flag
                    )
                )
            );
    }
}
