//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./common/Ownable.sol";
import "./interfaces/IWorld.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract World is Context, Ownable, ERC165, IWorld {
    using Address for address;
    using Strings for uint256;

    //  name
    string private _name;
    //  symbol
    string private _symbol;

    // constructor
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = _msgSender();
    }

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
            interfaceId == type(IWorld).interfaceId ||
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

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = World.ownerOf(tokenId);
        require(to != owner, "Item721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Item721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function approveById(uint256 to, uint256 tokenId) public virtual override {
        uint256 owner = World.ownerOfById(tokenId);
        require(to != owner, "Item721: approval to current owner");
        uint256 senderId = _getIdByAddress(_msgSender());
        require(
            senderId == owner || isApprovedForAllById(owner, senderId),
            "Item721: approve caller is not owner nor approved for all"
        );
        _approveById(to, tokenId);
    }

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
        _setApprovalForAllById(senderId, operator, approved);
    }

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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Item721: transfer caller is not owner nor approved"
        );
        _transferById(from, to, tokenId);
    }

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
        _transferById(from, to, tokenId);
        address fromAddr = _getAddressById(from);
        address toAddr = _getAddressById(to);
        require(
            _checkOnERC721Received(fromAddr, toAddr, tokenId, _data),
            "Item721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownersById[tokenId] != 0;
    }

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
        address owner = World.ownerOf(tokenId);
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
        uint256 owner = World.ownerOfById(tokenId);
        return (spender == owner ||
            isApprovedForAllById(owner, spender) ||
            getApprovedById(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "Item721: mint to the zero address");
        require(!_exists(tokenId), "Item721: token already minted");
        uint256 toId = _getIdByAddress(to);
        _balancesById[toId] += 1;
        _ownersById[tokenId] = toId;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = World.ownerOf(tokenId);
        _approve(address(0), tokenId);
        uint256 ownerId = _getIdByAddress(owner);
        _balancesById[ownerId] -= 1;
        delete _ownersById[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            World.ownerOf(tokenId) == from,
            "Item721: transfer from incorrect owner"
        );
        require(to != address(0), "Item721: transfer to the zero address");
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
        uint256 tokenId
    ) internal virtual {
        require(
            World.ownerOfById(tokenId) == from,
            "Item721: transfer from incorrect owner"
        );
        require(to != 0, "Item721: transfer to the zero");
        _approve(address(0), tokenId);
        _balancesById[from] -= 1;
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;
        emit TransferById(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        uint256 toId = _getIdByAddress(to);
        _tokenApprovalsById[tokenId] = toId;
        emit Approval(World.ownerOf(tokenId), to, tokenId);
    }

    function _approveById(uint256 to, uint256 tokenId) internal virtual {
        _tokenApprovalsById[tokenId] = to;
        emit ApprovalById(World.ownerOfById(tokenId), to, tokenId);
    }

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
        bool approved
    ) internal virtual {
        require(owner != operator, "Item721: approve to caller");
        _operatorApprovalsById[owner][operator] = approved;
        emit ApprovalForAllById(owner, operator, approved);
    }

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
        return _AddressesToIds[addr];
    }

    function _getAddressById(uint256 id) internal returns (address) {
        address addr;
        return _IdsToAddresses[id];
    }

    function getOrCreateAccountId(address _address)
        public
        virtual
        override
        returns (uint256 id)
    {}

    function getAddressById(uint256 _id)
        public
        view
        virtual
        override
        returns (address _address)
    {}

    enum TypeOperation {
        CASH,
        ITEM
    }

    // event 注册cash
    event RegisterCash(
        uint8 _type,
        address _contract,
        string _name,
        string _image
    );

    // event 注册item
    event RegisterItem(
        uint8 _type,
        address _contract,
        string _name,
        string _image
    );

    // event _worldOwner修改Asset _contract
    event ChangeAsset(address _contract, string _name, string _image);

    // event 创建Account
    event CreateAccount(uint256 _id, address _address);

    // event 修改Account _address
    event ChangeAccount(uint256 _id, address _executor, address _newAddress);

    // struct Account
    struct Account {
        uint8 _level;
        bool _isTrustAdmin;
        bool _isExist;
        uint256 _id;
        address _address;
    }

    mapping(uint256 => mapping(address => bool)) private _trustContracts;
    mapping(uint256 => Account) private _accountsById;
    mapping(address => Account) private _accountsByAddress;

    // struct Asset
    struct Asset {
        uint8 _type;
        bool _isExist;
        address _contract;
        string _name;
        string _image;
    }

    // avatar最大数量
    uint256 public constant MAX_AVATAR_INDEX = 100000;

    // account 账户Id
    uint256 public accountId;

    // 全局资产
    mapping(address => Asset) private _assets;

    // func 注册cash
    function registerCash(
        address _contract,
        string calldata _tokneName,
        string calldata _image
    ) public onlyOwner {
        require(
            _contract != address(0) && _assets[_contract]._isExist == false,
            "contract is invalid"
        );

        Asset memory asset = Asset(
            uint8(TypeOperation.CASH),
            true,
            _contract,
            _tokneName,
            _image
        );

        _assets[_contract] = asset;
        emit RegisterCash(uint8(TypeOperation.CASH), _contract, _name, _image);
    }

    // func 注册item
    function registerItem(
        address _contract,
        string calldata _tokneName,
        string calldata _image
    ) public onlyOwner {
        require(
            _contract != address(0) && _assets[_contract]._isExist == false,
            "contract is invalid"
        );

        Asset memory asset = Asset(
            uint8(TypeOperation.ITEM),
            true,
            _contract,
            _tokneName,
            _image
        );

        _assets[_contract] = asset;
        emit RegisterItem(uint8(TypeOperation.ITEM), _contract, _name, _image);
    }

    // func 修改Asset _contract
    function changeAsset(address _contract, Asset memory asset)
        public
        onlyOwner
    {
        require(
            _contract != address(0) &&
                _assets[_contract]._isExist == true &&
                _assets[_contract]._type == asset._type,
            "asset is invalid"
        );

        _assets[_contract] = asset;
        emit ChangeAsset(_contract, asset._name, asset._image);
    }

    // func 创建Account
    function createAccount(address _address) public {
        require(
            _address != address(0) &&
                _accountsByAddress[_address]._isExist == false,
            "address is invalid"
        );

        uint256 id = accountId++;

        Account memory account = Account(
            0,
            false,
            true,
            id,
            _address
        );

        _accountsById[id] = account;
        _accountsByAddress[_address] = account;
        emit CreateAccount(id, _address);
    }

    // func world修改Account _address
    function changeAccountByWorld(uint256 _id, address _newAddress) public onlyOwner {
        require(
            _id != 0 &&
                _accountsById[_id]._isExist == true &&
                _accountsByAddress[_newAddress]._isExist == false,
            "account is invalid"
        );

        Account memory account = _accountsById[_id];
        delete _accountsByAddress[account._address];
        account._address = _newAddress;
        _accountsById[_id] = account;
        _accountsByAddress[_newAddress] = account;
        
        // todo 修改assets

        emit ChangeAccount(_id, _msgSender(), _newAddress);
    }

    // func user修改Account _address
    function changeAccountByUser(uint256 _id, address _newAddress) public {
        require(
            _id != 0 &&
                _accountsById[_id]._isExist == true &&
                _accountsByAddress[_newAddress]._isExist == false&&
                _accountsById[_id]._address == _msgSender(),
            "account is invalid"
        );

        Account memory account = _accountsById[_id];
        delete _accountsByAddress[account._address];
        account._address = _newAddress;
        _accountsById[_id] = account;
        _accountsByAddress[_newAddress] = account;

        // todo 修改assets

        emit ChangeAccount(_id, _msgSender(), _newAddress);
    }

    // func 获取Account
    function getAccount(uint256 _id) public view returns (Account memory) {
        require(_id != 0 && _accountsById[_id]._isExist == true, "account is invalid");
        return _accountsById[_id];
    }

    // func 通过_address 获取Account
    function getAccountByAddress(address _address)
        public
        view
        returns (Account memory)
    {
        require(_address != address(0) && _accountsByAddress[_address]._isExist == true, "account is invalid");
        return _accountsByAddress[_address];
    }

    // func 判断Holder是否为Avatar
    function isAvatar(uint256 _id) public view returns (bool isAvatar) {}

    // func 判断Holder（Avatar或者Account）是否存在
    function holderExist(uint256 _id) public view returns (bool exist) {}

    // func 获取Asset
    function getAsset(address _contract) public view returns (Asset memory) {
        require(_contract != address(0) && _assets[_contract]._isExist == true, "asset is invalid");
        return _assets[_contract];
    }
}
