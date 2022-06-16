//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IItem721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Item721 is EIP712, ERC165, IItem721 {
    using Address for address;

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // world addr
    address private _world;
    // owner addr
    address private _owner;

    // nonce
    mapping(address => uint256) private _nonces;

    // Mapping from token ID to owner address
    mapping(uint256 => uint256) private _ownersById;

    // Mapping owner address to token count
    mapping(uint256 => uint256) private _balancesById;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovalsById;

    // Mapping from owner to operator approvals
    mapping(uint256 => mapping(address => bool)) private _operatorApprovalsById;

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
        require(owner != address(0), "Item: address zero is not a valid owner");
        return _balancesById[_getAccountIdByAddress(owner)];
    }

    /**
     * @dev See {IItem721-balanceOfItem}.
     */
    function balanceOfItem(uint256 ownerId)
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
        address owner = _getAddressById(_ownersById[tokenId]);
        require(owner != address(0), "Item: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IItem721-ownerOfItem}.
     */
    function ownerOfItem(uint256 tokenId)
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

    function getNonce(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _nonces[account];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

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

    function approve(address to, uint256 tokenId) public virtual override {
        _checkAndApprove(msg.sender, to, tokenId);
    }

    function _checkAndApprove(
        address sender,
        address to,
        uint256 tokenId
    ) internal virtual {
        address owner = Item721.ownerOf(tokenId);
        require(to != owner, "Item: approval to current owner");
        require(sender == owner || isApprovedForAll(owner, sender), "Item: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function approveItemBWO(
        address to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        require(_isBWO(msg.sender), "Item: must be the BWO");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(address to,uint256 tokenId,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        to,
                        tokenId,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        require(block.timestamp < deadline, "Cash: signed transaction expired");
        _checkAndApprove(sender, to, tokenId);
        emit ApprovalItemBWO(to, tokenId, sender, nonce, deadline);
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
        _setApprovalForAllItem(_getIdByAddress(msg.sender), operator, approved);
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function setApprovalForAllItem(
        uint256 from,
        address to,
        bool approved
    ) public virtual override {
        _checkAndSetApprovalForAllItem(msg.sender, from, to, approved);
    }

    function _checkAndSetApprovalForAllItem(
        address sender,
        uint256 from,
        address to,
        bool approved
    ) internal virtual {
        require(_checkAddress(sender, from), "Item: not owner");
        _setApprovalForAllItem(from, to, approved);
    }

    function setApprovalForAllItemBWO(
        uint256 from,
        address to,
        bool approved,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        require(_isBWO(msg.sender), "Item: must be the BWO");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 from,address to,bool approved,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        from,
                        to,
                        approved,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        require(block.timestamp < deadline, "Cash: signed transaction expired");
        _checkAndSetApprovalForAllItem(sender, from, to, approved);
        emit ApprovalForAllItemBWO(from, to, approved, sender, nonce, deadline);
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
        if (_isBWO(operator)) {
            return true;
        }
        return _operatorApprovalsById[_getAccountIdByAddress(owner)][operator];
    }

    function isApprovedForAllItem(uint256 owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (_isBWO(operator)) {
            return true;
        }
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
        transferFromItem(_getIdByAddress(from), _getIdByAddress(to), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function transferFromItem(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        _checkAndTransfer(msg.sender, from, to, tokenId);
    }

    function _checkAndTransfer(
        address sender,
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) internal virtual {
        require(_isApprovedOrOwner(sender, tokenId), "Item: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function transferFromItemBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        require(_isBWO(msg.sender), "Item: must be the BWO");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 from,uint256 to,uint256 tokenId,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        from,
                        to,
                        tokenId,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        require(block.timestamp < deadline, "Cash: signed transaction expired");
        _checkAndTransfer(sender, from, to, tokenId);
        emit TransferItemBWO(from, to, tokenId, sender, nonce, deadline);
        _nonces[sender] += 1;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(to != address(0), "Item: transfer to the zero address");
        uint256 fromId = _getIdByAddress(from);
        uint256 toId = _getIdByAddress(to);
        _checkAndSafeTransfer(msg.sender, fromId, toId, tokenId, "");
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFromItem(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        _checkAndSafeTransfer(msg.sender, from, to, tokenId, "");
    }

    function safeTransferFromItemBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        require(_isBWO(msg.sender), "Item: must be the BWO");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 from,uint256 to,uint256 tokenId,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        from,
                        to,
                        tokenId,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        require(block.timestamp < deadline, "Cash: signed transaction expired");
        _checkAndSafeTransfer(sender, from, to, tokenId, "");
        emit TransferItemBWO(from, to, tokenId, sender, nonce, deadline);
        _nonces[sender] += 1;
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
        require(to != address(0), "Item: transfer to the zero address");
        uint256 fromId = _getIdByAddress(from);
        uint256 toId = _getIdByAddress(to);
        _checkAndSafeTransfer(msg.sender, fromId, toId, tokenId, _data);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFromItem(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _checkAndSafeTransfer(msg.sender, from, to, tokenId, _data);
    }

    function _checkAndSafeTransfer(
        address sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        require(_isApprovedOrOwner(sender, tokenId), "Item: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
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
        require(_isBWO(msg.sender), "Item: must be the BWO");
        uint256 nonce = _nonces[sender];
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

        require(block.timestamp < deadline, "Cash: signed transaction expired");
        _checkAndSafeTransfer(sender, from, to, tokenId, data);
        emit TransferItemBWO(from, to, tokenId, sender, nonce, deadline);
        _nonces[sender] += 1;
    }

    function _safeTransfer(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(
                _getAddressById(from),
                _getAddressById(to),
                tokenId,
                _data
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
        address owner = Item721.ownerOf(tokenId);
        uint256 ownerId = Item721.ownerOfItem(tokenId);

        return (sender == owner ||
            IWorld(_world).isTrust(sender, ownerId) ||
            isApprovedForAll(owner, sender) ||
            getApproved(tokenId) == sender);
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
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "Item: transfer to non ERC721Receiver implementer");
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
        _mintItem(_getIdByAddress(to), tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    function _mintItem(uint256 to, uint256 tokenId) internal virtual {
        require(to != 0, "Item: transfer to the zero id");
        require(!_exists(tokenId), "Item: token already minted");

        _balancesById[to] += 1;
        _ownersById[tokenId] = to;
        emit TransferItem(0, to, tokenId);
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
        emit TransferItem(ownerId, 0, tokenId);
    }

    function _transfer(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) internal virtual {
        require(Item721.ownerOfItem(tokenId) == from, "Item: transfer from incorrect owner");
        require(to != 0, "Item: transfer to the zero id");
        require(_accountIsExist(to), "Item: to account is not exist");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balancesById[from] -= 1;
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;

        emit TransferItem(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovalsById[tokenId] = to;
        emit Approval(Item721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAllItem(
        uint256 owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != 0, "Item: id zero is not a valid owner");
        require(owner != _getAccountIdByAddress(operator), "Item: approve to caller");
        _operatorApprovalsById[owner][operator] = approved;
        emit ApprovalForAllItem(owner, operator, approved);
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

    function _getAccountIdByAddress(address addr)
        internal
        view
        returns (uint256)
    {
        return IWorld(_world).getAccountIdByAddress(addr);
    }

    function _getIdByAddress(address addr) internal returns (uint256) {
        return IWorld(_world).getOrCreateAccountId(addr);
    }

    function _getAddressById(uint256 id) internal view returns (address) {
        return IWorld(_world).getAddressById(id);
    }

    function _checkAddress(address addr, uint256 id)
        internal
        view
        returns (bool)
    {
        return IWorld(_world).checkAddress(addr, id);
    }

    function _accountIsExist(uint256 _id) internal view returns (bool) {
        return IWorld(_world).getAddressById(_id) != address(0);
    }

    function _isBWO(address _add) internal view returns (bool) {
        return IWorld(_world).isBWO(_add);
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "Item: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "Item: recoverSig failed");
    }
}
