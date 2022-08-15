//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IItem721.sol";
import "../interfaces/IWorldAsset.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Item721 is EIP712, ERC165, IItem721 {
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
    // owner addr
    address private _owner;
    // tokenURI
    string private _tokenURI;

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
        _metadverse = IWorld(world_).getMetaverse();
        _owner = msg.sender;
    }

    function updateWorld(address world) public {
        _onlyOwner();
        require(
            _metadverse == IWorld(world).getMetaverse(),
            "Item: metaverse not match"
        );
        _world = world;
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
        _checkIdIsNotZero(ownerId, "Item: id zero is not a valid owner");
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
        returns (address owner)
    {
        owner = _getAddressById(_ownersById[tokenId]);
        _checkAddrIsNotZero(owner, "Item: owner query for nonexistent token");
    }

    /**
     * @dev See {IItem721-ownerOfItem}.
     */
    function ownerOfItem(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256 ownerId)
    {
        ownerId = _ownersById[tokenId];
        _checkIdIsNotZero(ownerId, "Item: owner query for nonexistent token");
    }

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

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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

    function setTokenURI(string memory uri) public {
        _onlyOwner();
        _tokenURI = uri;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = Item721.ownerOf(tokenId);
        require(to != owner, "Item: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Item: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function approveItem(
        uint256 from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _checkAddress(msg.sender, from);
        approve(to, tokenId);
    }

    function approveItemBWO(
        address to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        _isBWO(msg.sender);
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
        require(to != sender, "Item: approval to current owner");
        _checkAddressProxy(sender, ownerOfItem(tokenId));
        _approve(to, tokenId);
        emit ApprovalItemBWO(to, tokenId, sender, nonce);
        _nonces[sender] += 1;
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovalsById[tokenId] = to;
        emit Approval(Item721.ownerOf(tokenId), to, tokenId);
        emit ApprovalItem(Item721.ownerOfItem(tokenId), to, tokenId);
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
        _checkAddress(msg.sender, from);
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
        _isBWO(msg.sender);

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
        _checkAddressProxy(sender, from);
        _setApprovalForAllItem(from, to, approved);
        emit ApprovalForAllItemBWO(from, to, approved, sender, nonce);
        _nonces[sender] += 1;
    }

    function _setApprovalForAllItem(
        uint256 owner,
        address operator,
        bool approved
    ) internal virtual {
        _checkIdIsNotZero(owner, "Item: id zero is not a valid owner");
        _isFreeze(owner, "Item: owner is frozen");
        require(operator != _getAddressById(owner), "Item: approve to caller");
        _operatorApprovalsById[owner][operator] = approved;
        emit ApprovalForAllItem(owner, operator, approved);
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
        uint256 ownerId = _getAccountIdByAddress(owner);
        if (_isTrust(operator, ownerId)) {
            return true;
        }
        return _operatorApprovalsById[ownerId][operator];
    }

    function isApprovedForAllItem(uint256 owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (_isTrust(operator, owner)) {
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
        _checkAddrIsNotZero(to, "Item: transfer to the zero address");
        transferFromItem(_getIdByAddress(from), _getIdByAddress(to), tokenId);
    }

    function transferFromItem(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Item: transfer caller is not owner nor approved"
        );
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
        _isBWO(msg.sender);

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

        _checkAddressProxy(sender, from);
        _transfer(from, to, tokenId);
        emit TransferItemBWO(from, to, tokenId, sender, nonce);
        _nonces[sender] += 1;
    }

    function _transfer(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) internal virtual {
        require(
            Item721.ownerOfItem(tokenId) == from,
            "Item: transfer from incorrect owner"
        );
        _isFreeze(from, "Item: transfer from frozen account");
        _checkIdIsNotZero(to, "Item: transfer to the zero id");
        _accountIsExist(to);

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balancesById[from] -= 1;
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;

        emit TransferItem(from, to, tokenId);
        emit Transfer(_getAddressById(from), _getAddressById(to), tokenId);
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
        safeTransferFromItem(
            _getIdByAddress(from),
            _getIdByAddress(to),
            tokenId,
            data
        );
    }

    function safeTransferFromItem(
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
        _isBWO(msg.sender);
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

        _checkAddressProxy(sender, from);
        _safeTransfer(from, to, tokenId, data);
        emit TransferItemBWO(from, to, tokenId, sender, nonce);
        _nonces[sender] += 1;
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
                _getAddressById(from),
                _getAddressById(to),
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
        address owner = Item721.ownerOf(tokenId);

        return (sender == owner ||
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
        _mintItem(_getIdByAddress(to), tokenId);
    }

    function _mintItem(uint256 to, uint256 tokenId) internal virtual {
        _checkIdIsNotZero(to, "Item: transfer to the zero id");
        require(!_exists(tokenId), "Item: token already minted");
        _beforeTokenTransfer(0, to, tokenId);
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;
        emit TransferItem(0, to, tokenId);
        emit Transfer(address(0), _getAddressById(to), tokenId);
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
        _beforeTokenTransfer(ownerId, 0, tokenId);
        _balancesById[ownerId] -= 1;
        delete _ownersById[tokenId];

        emit Transfer(owner, address(0), tokenId);
        emit TransferItem(ownerId, 0, tokenId);
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

    function _checkAddress(address addr, uint256 id) internal view {
        require(
            IWorld(_world).checkAddress(addr, id, false),
            "Item: not owner"
        );
    }

    function _checkAddressProxy(address _addr, uint256 _id) internal view {
        require(
            IWorld(_world).checkAddress(_addr, _id, true),
            "Item: not owner or auth"
        );
    }

    function _accountIsExist(uint256 _id) internal view {
        require(
            IWorld(_world).getAddressById(_id) != address(0),
            "Item: to account is not exist"
        );
    }

    function _isBWO(address _add) internal view {
        require(IWorld(_world).isBWOByAsset(_add), "Item: must be the BWO");
    }

    function _isTrust(address _contract, uint256 _id)
        internal
        view
        returns (bool)
    {
        return IWorld(_world).isTrustByAsset(_contract, _id);
    }

    function _isFreeze(uint256 _id, string memory _msg) internal view {
        require(!IWorld(_world).isFreeze(_id), _msg);
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

    function _onlyOwner() internal view {
        require(_owner == msg.sender, "Item: only owner");
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
