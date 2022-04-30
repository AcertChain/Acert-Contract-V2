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
    // event add operator
    event AddOperator(address _operator);
    // event remove operator
    event RemoveOperator(address _operator);
    // event add contract
    event AddContract(address _contract);
    // event remove contract
    event RemoveContract(address _contract);

    //  name
    string private _name;
    //  symbol
    string private _symbol;
    //  supply
    uint256 private _supply;
    // account Id
    uint256 private accountId;

    // constructor
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _supply = supply_;
        _owner = _msgSender();
    }

    // struct Asset
    struct Asset {
        uint8 _type;
        bool _isExist;
        address _contract;
        string _name;
        string _image;
    }
    // struct Account
    struct Account {
        uint8 _level;
        bool _isTrustWorld;
        bool _isExist;
        uint256 _id;
        address _address;
    }

    // Mapping from address to operator
    mapping(address => bool) private _isOperatorByAddress;
    
    // Mapping from address to trust contract
    mapping(address => bool) private _trustContracts;

    // Mapping from address to Asset
    mapping(address => Asset) private _assets;

    // Mapping from owner ID to Account
    mapping(uint256 => Account) private _accountsById;

    // Mapping from adress to owner ID
    mapping(address => uint256) private _addressesToIds;

    // Mapping from token ID to owner ID
    mapping(uint256 => uint256) private _ownersById;

    // Mapping account ID to token count
    mapping(uint256 => uint256) private _balancesById;

    // Mapping from token ID to approved account ID
    mapping(uint256 => uint256) private _tokenApprovalsById;

    // Mapping from owner to operator approvals
    mapping(uint256 => mapping(uint256 => bool)) private _operatorApprovalsById;

    

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
            "World: address zero is not a valid owner"
        );
        return _balancesById[_addressesToIds[owner]];
    }

    function balanceOfById(uint256 ownerId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(ownerId != 0, "World: id zero is not a valid owner");
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
        address owner = _accountsById[ownerId]._address;
        require(
            owner != address(0),
            "World: owner query for nonexistent token"
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
        require(owner != 0, "World: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _supply;
    }

    function getAccountId() public view virtual returns (uint256) {
        return accountId;
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
        require(to != owner, "World: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "World: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function approveById(uint256 to, uint256 tokenId) public virtual override {
        uint256 owner = World.ownerOfById(tokenId);
        require(to != owner, "World: approval to current owner");
        uint256 senderId = _addressesToIds[_msgSender()];
        require(
            senderId == owner || isApprovedForAllById(owner, senderId),
            "World: approve caller is not owner nor approved for all"
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
            "World: approved query for nonexistent token"
        );
        return _accountsById[_tokenApprovalsById[tokenId]]._address;
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
            "World: approved query for nonexistent token"
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
        uint256 senderId = _addressesToIds[_msgSender()];
        _setApprovalForAllById(senderId, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        uint256 ownerId = _addressesToIds[owner];
        uint256 operatorId = _addressesToIds[operator];
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
            "World: transfer caller is not owner nor approved"
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
            "World: transfer caller is not owner nor approved"
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
            "World: transfer caller is not owner nor approved"
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
            "World: transfer caller is not owner nor approved"
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
            "World: transfer to non ERC721Receiver implementer"
        );
    }

    function _safeTransferById(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transferById(from, to, tokenId);
        address fromAddr = _accountsById[from]._address;
        address toAddr = _accountsById[to]._address;
        require(
            _checkOnERC721Received(fromAddr, toAddr, tokenId, _data),
            "World: transfer to non ERC721Receiver implementer"
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
            "World: operator query for nonexistent token"
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
            "World: operator query for nonexistent token"
        );
        uint256 owner = World.ownerOfById(tokenId);
        return (spender == owner ||
            isApprovedForAllById(owner, spender) ||
            getApprovedById(tokenId) == spender);
    }

    function mint() public onlyOwner {}

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
            "World: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "World: mint to the zero address");
        require(!_exists(tokenId), "World: token already minted");
        uint256 toId = _addressesToIds[to];

        _balancesById[toId] += 1;
        _ownersById[tokenId] = toId;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = World.ownerOf(tokenId);
        _approve(address(0), tokenId);
        uint256 ownerId = _addressesToIds[owner];
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
            "World: transfer from incorrect owner"
        );
        require(to != address(0), "World: transfer to the zero address");
        _approve(address(0), tokenId);
        uint256 fromId = _addressesToIds[from];
        uint256 toId = _addressesToIds[to];
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
            "World: transfer from incorrect owner"
        );
        require(to != 0, "World: transfer to the zero");
        _approve(address(0), tokenId);
        _balancesById[from] -= 1;
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;
        emit TransferById(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        uint256 toId = _addressesToIds[to];
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
        require(owner != operator, "World: approve to caller");
        uint256 ownerId = _addressesToIds[owner];
        uint256 operatorId = _addressesToIds[operator];
        _operatorApprovalsById[ownerId][operatorId] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _setApprovalForAllById(
        uint256 owner,
        uint256 operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "World: approve to caller");
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
                    revert("World: transfer to non ERC721Receiver implementer");
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

    function getOrCreateAccountId(address _address)
        public
        virtual
        override
        returns (uint256 id)
    {
        require(
            _address != address(0),
            "World: getOrCreateAccountId with zero address"
        );
        if (_addressesToIds[_address] == 0) {
            // create account
            accountId++;
            id = accountId;
            Account memory account = Account(0, false, true, id, _address);
            _accountsById[id] = account;
            _addressesToIds[_address] = id;
            emit CreateAccount(id, _address);
        } else {
            id = _addressesToIds[_address];
        }
    }

    function getAddressById(uint256 _id)
        public
        view
        virtual
        override
        returns (address _address)
    {
        return _accountsById[_id]._address;
    }

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
            _address != address(0) && _addressesToIds[_address] != 0,
            "address is invalid"
        );
        accountId++;
        uint256 id = accountId;
        Account memory account = Account(0, false, true, id, _address);
        _accountsById[id] = account;
        _addressesToIds[_address] = id;
        emit CreateAccount(id, _address);
    }

    // func world修改Account _address
    function changeAccountByWorld(uint256 _id, address _newAddress)
        public
        onlyOwner
    {
        require(
            _id != 0 &&
                _accountsById[_id]._isExist == true &&
                _addressesToIds[_newAddress] != 0,
            "account is invalid"
        );

        Account memory account = _accountsById[_id];
        delete _addressesToIds[account._address];
        account._address = _newAddress;
        _accountsById[_id] = account;
        _addressesToIds[_newAddress] = _id;

        // todo 修改assets
        emit ChangeAccount(_id, _msgSender(), _newAddress);
    }

    // func user修改Account _address
    function changeAccountByUser(uint256 _id, address _newAddress) public {
        require(
            _id != 0 &&
                _accountsById[_id]._isExist == true &&
                _addressesToIds[_newAddress] != 0 &&
                _accountsById[_id]._address == _msgSender(),
            "account is invalid"
        );

        Account memory account = _accountsById[_id];
        delete _addressesToIds[account._address];
        account._address = _newAddress;
        _accountsById[_id] = account;
        _addressesToIds[_newAddress] = _id;

        // todo 修改assets
        emit ChangeAccount(_id, _msgSender(), _newAddress);
    }

    // 添加operator
    function addOperator(address _operator) public onlyOwner {
        require(_operator != address(0), "operator is invalid");
        _isOperatorByAddress[_operator] = true;
        emit AddOperator(_operator);
    }

    // 删除operator
    function removeOperator(address _operator) public onlyOwner {
        require(_operator != address(0), "operator is invalid");
        _isOperatorByAddress[_operator] = false;
        emit RemoveOperator(_operator);
    }

    // is operator
    function isOperator(address _operator) public view returns (bool) {
        return _isOperatorByAddress[_operator];
    }

    // 添加conttract
    function addContract(address _contract) public onlyOwner {
        require(_contract != address(0), "contract is invalid");
        _trustContracts[_contract] = true;
        emit AddContract(_contract);
    }
    // 删除contract
    function removeContract(address _contract) public onlyOwner {
        require(_contract != address(0), "contract is invalid");
        _trustContracts[_contract] = false;
        emit RemoveContract(_contract);
    }

    // is contract
    function isContract(address _contract) public view returns (bool) {
        return _trustContracts[_contract];
    }

    // func 获取Account
    function getAccount(uint256 _id) public view returns (Account memory) {
        require(
            _id != 0 && _accountsById[_id]._isExist == true,
            "account is invalid"
        );
        return _accountsById[_id];
    }

    // func 通过_address 获取Account
    function getAccountByAddress(address _address)
        public
        view
        returns (Account memory)
    {
        require(
            _address != address(0) && _addressesToIds[_address] != 0,
            "account is invalid"
        );
        return _accountsById[_addressesToIds[_address]];
    }

    // func 获取Asset
    function getAsset(address _contract) public view returns (Asset memory) {
        require(
            _contract != address(0) && _assets[_contract]._isExist == true,
            "asset is invalid"
        );
        return _assets[_contract];
    }
}
