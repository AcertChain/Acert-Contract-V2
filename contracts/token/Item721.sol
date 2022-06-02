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

/**
I01:must be the BWO
I02:recoverSig failed
I03:BWO call expired
I04:approval to current owner
I05:approve caller is not owner nor approved for all
I06:Item: address zero is not a valid owner
I07:Item: id zero is not a valid owner
I08:Item: owner query for nonexistent token
I09:Item: approval to current owner
I10:Item: approve caller is not owner nor approved for all
I11:Item: approved query for nonexistent token
I12:Item: approve to caller
I13:Item: transfer to the zero address
I14:Item: transfer caller is not owner nor approved
I15:Item: transfer to non ERC721Receiver implementer
I16:Item: operator query for nonexistent token
I17:Item: mint to the zero address
I18:Item: token already minted
I19:Item: transfer from incorrect owner
I20:Item: transfer to the zero address or zero id
I21:Item: must be the world
I22:Item: not owner
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

    // nonce
    mapping(uint256 => uint256) private _nonces;

    // Mapping from token ID to owner address
    mapping(uint256 => uint256) private _ownersById;

    // Mapping owner address to token count
    mapping(uint256 => uint256) private _balancesById;

    // Mapping from token ID to approved address
    mapping(uint256 => uint256) private _tokenApprovalsById;

    // Mapping from owner to operator approvals
    mapping(uint256 => mapping(address => bool)) private _operatorApprovalsById;

    mapping(address => uint256) private _AddrToId;

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
        require(owner != address(0), "I06");
        return _balancesById[_AddrToId[owner]];
    }

    /**
     * @dev See {IItem721-balanceOfId}.
     */
    function balanceOfId(uint256 ownerId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(ownerId != 0, "I07");
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
        address owner = IWorld(_world).getAddressById(_ownersById[tokenId]);
        require(owner != address(0), "I08");
        return owner;
    }

    /**
     * @dev See {IItem721-ownerOfId}.
     */
    function ownerOfId(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 owner = _ownersById[tokenId];
        require(owner != 0, "I08");
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
        address owner = Item721.ownerOf(tokenId);
        require(to != owner, "I09");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "I10"
        );
        _approve(_getIdByAddress(to), tokenId, TypeOperation.ADDRESS);
    }

    function approveId(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        uint256 owner = Item721.ownerOfId(tokenId);
        address sender = msg.sender;
        require(to != owner, "I09");
        require(IWorld(_world).checkAddress(sender, from), "I22");
        require(from == owner || isApprovedForAllId(owner, sender), "I10");
        _approve(to, tokenId, TypeOperation.ID);
    }

    function approveBWO(
        address from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        require(IWorld(_world).isBWO(msg.sender), "I01");
        uint256 fromId = _getIdByAddress(from);
        uint256 nonce = _nonces[fromId];
        _recoverSig(
            deadline,
            from,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(address from,uint256 to,uint256 tokenId,uint256 nonce,uint256 deadline)"
                        ),
                        from,
                        to,
                        tokenId,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        uint256 owner = Item721.ownerOfId(tokenId);
        require(to != owner, "I09");
        require(fromId == owner || isApprovedForAllId(owner, from), "I10");
        _nonces[fromId] += 1;
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
        require(_exists(tokenId), "I11");
        return IWorld(_world).getAddressById(_tokenApprovalsById[tokenId]);
    }

    function getApprovedId(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(_exists(tokenId), "I11");
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
        require(msg.sender != operator, "I12");
        _operatorApprovalsById[_getIdByAddress(msg.sender)][
            operator
        ] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function setApprovalForAllId(
        uint256 sender,
        address operator,
        bool approved
    ) public virtual override {
        require(IWorld(_world).checkAddress(msg.sender, sender), "I22");
        _setApprovalForAllId(sender, operator, approved, false);
    }

    function setApprovalForAllBWO(
        uint256 sender,
        address operator,
        bool approved,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        require(IWorld(_world).isBWO(msg.sender), "I01");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            _updateAddressById(sender),
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 sender,address operator,uint256 nonce,uint256 deadline,bool approved)"
                        ),
                        sender,
                        operator,
                        nonce,
                        deadline,
                        approved
                    )
                )
            ),
            signature
        );
        _nonces[sender] += 1;
        _setApprovalForAllId(sender, operator, approved, true);
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
        return _operatorApprovalsById[_AddrToId[owner]][operator];
    }

    function isApprovedForAllId(uint256 owner, address operator)
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
        require(to != address(0), "I13");
        uint256 fromId = _getIdByAddress(from);
        uint256 toId = _getIdByAddress(to);
        if (IWorld(_world).isTrust(msg.sender, fromId)) {
            _transfer(fromId, toId, tokenId, TypeOperation.ADDRESS);
        }

        require(_isApprovedOrOwner(msg.sender, tokenId), "I14");

        _transfer(fromId, toId, tokenId, TypeOperation.ADDRESS);
    }

    function transferItemFrom(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        if (IWorld(_world).isTrust(msg.sender, from)) {
            _transfer(from, to, tokenId, TypeOperation.ID);
        }

        require(IWorld(_world).checkAddress(msg.sender, sender), "I22");
        require(_isApprovedOrOwner(_updateAddressById(sender), tokenId), "I14");
        _transfer(from, to, tokenId, TypeOperation.ID);
    }

    function transferFromBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        require(IWorld(_world).isBWO(msg.sender), "I01");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            _updateAddressById(sender),
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 sender,uint256 from,uint256 to,uint256 tokenId,uint256 nonce,uint256 deadline)"
                        ),
                        sender,
                        from,
                        to,
                        tokenId,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        require(_isApprovedOrOwner(_updateAddressById(sender), tokenId), "I14");
        _nonces[sender] += 1;
        _transfer(from, to, tokenId, TypeOperation.BWO);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferItemFrom(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        safeTransferItemFrom(sender, from, to, tokenId, "");
    }

    function safeTransferFromBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) public virtual override {
        require(IWorld(_world).isBWO(msg.sender), "I01");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            _updateAddressById(sender),
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 sender,uint256 from,uint256 to,uint256 tokenId,uint256 nonce,uint256 deadline)"
                        ),
                        sender,
                        from,
                        to,
                        tokenId,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );

        _nonces[sender] += 1;

        require(_isApprovedOrOwner(_updateAddressById(sender), tokenId), "I14");
        _safeTransfer(from, to, tokenId, "", TypeOperation.BWO);
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
        require(_isApprovedOrOwner(msg.sender, tokenId), "I14");
        require(to != address(0), "I13");
        _safeTransfer(
            _getIdByAddress(from),
            _getIdByAddress(to),
            tokenId,
            _data,
            TypeOperation.ADDRESS
        );
    }

    function safeTransferItemFrom(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(IWorld(_world).checkAddress(msg.sender, sender), "I22");
        require(_isApprovedOrOwner(_updateAddressById(sender), tokenId), "I14");
        _safeTransfer(from, to, tokenId, _data, TypeOperation.ID);
    }

    function safeTransferFromBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory data,
        bytes memory signature
    ) public virtual override {
        require(IWorld(_world).isBWO(msg.sender), "I01");
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            _updateAddressById(sender),
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 sender,uint256 from,uint256 to,uint256 tokenId,uint256 nonce,uint256 deadline,bytes data)"
                        ),
                        sender,
                        from,
                        to,
                        tokenId,
                        nonce,
                        deadline,
                        keccak256(data)
                    )
                )
            ),
            signature
        );

        _nonces[sender] += 1;

        require(_isApprovedOrOwner(_updateAddressById(sender), tokenId), "I14");
        _safeTransfer(from, to, tokenId, data, TypeOperation.BWO);
    }

    function updateAccountAddress(
        uint256 id,
        address newAddr,
        address oldAddr
    ) public virtual override returns (bool) {
        require(_world == msg.sender, "I21");
        _AddrToId[newAddr] = id;
        delete _AddrToId[oldAddr];
        return true;
    }

    function _safeTransfer(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data,
        TypeOperation op
    ) internal virtual {
        _transfer(from, to, tokenId, op);
        address fromAddr = _updateAddressById(from);
        address toAddr = _updateAddressById(to);
        require(
            _checkOnERC721Received(fromAddr, toAddr, tokenId, _data),
            "I15"
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
        require(_exists(tokenId), "I16");
        address owner = Item721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
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
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "I15");
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
        require(to != address(0), "I17");
        require(!_exists(tokenId), "I18");

        uint256 toId = _getIdByAddress(to);

        _balancesById[toId] += 1;
        _ownersById[tokenId] = toId;

        emit Transfer(address(0), to, tokenId);
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

        _balancesById[_getIdByAddress(owner)] -= 1;
        delete _ownersById[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        TypeOperation operation
    ) internal virtual {
        require(Item721.ownerOfId(tokenId) == from, "I19");
        require(to != 0, "I20");

        // Clear approvals from the previous owner
        _approve(0, tokenId, operation);

        _balancesById[from] -= 1;
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;

        if (operation == TypeOperation.BWO) {
            emit TransferBWO(from, to, tokenId);
        } else if (operation == TypeOperation.ID) {
            emit TransferId(from, to, tokenId);
        } else {
            emit Transfer(
                _updateAddressById(from),
                _updateAddressById(to),
                tokenId
            );
        }
    }

    function _approve(
        uint256 to,
        uint256 tokenId,
        TypeOperation typeOperation
    ) internal virtual {
        _tokenApprovalsById[tokenId] = to;
        if (typeOperation == TypeOperation.BWO) {
            emit ApprovalBWO(Item721.ownerOfId(tokenId), to, tokenId);
        } else if (typeOperation == TypeOperation.ID) {
            emit ApprovalId(Item721.ownerOfId(tokenId), to, tokenId);
        } else {
            emit Approval(
                Item721.ownerOf(tokenId),
                _updateAddressById(to),
                tokenId
            );
        }
    }

    function _setApprovalForAllId(
        uint256 owner,
        address operator,
        bool approved,
        bool isBWO
    ) internal virtual {
        require(owner != _AddrToId[operator], "I12");
        _operatorApprovalsById[owner][operator] = approved;
        if (isBWO) {
            emit ApprovalForAllBWO(owner, operator, approved);
        } else {
            emit ApprovalForAllId(owner, operator, approved);
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
                    revert("I15");
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
        uint256 id = IWorld(_world).getOrCreateAccountId(addr);
        _AddrToId[addr] = id;
        return id;
    }

    function _updateAddressById(uint256 id) internal returns (address) {
        address addr = IWorld(_world).getAddressById(id);
        _AddrToId[addr] = id;
        return addr;
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "I03");
        require(signer == ECDSA.recover(digest, signature), "I02");
    }
}
