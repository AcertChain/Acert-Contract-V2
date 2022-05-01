//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IWorld.sol";
import "./interfaces/IAsset.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
W01:not equal
W02:approve caller is not owner nor approved for all
W03:token is not exist
W04:transfer caller is not owner nor approved
W05:transfer to non ERC721Receiver implementer
W06:zero id
W07:token is exist
W08:transfer from incorrect owner
W09:zero address
W10:contract is invalid or is exist
W11:world is not equal
W12:asset is invalid
W13:address is invalid or is exist
W14:only operator or world can exec
W15:empty data
W16:asset is invalid or is not exist
W17:account is invalid or is not exist
W18:only owner
W19:contract is not safe contract
W20:account not trust contract
 */
contract World is ERC165, IWorld {
    enum TypeOperation {
        CASH,
        ITEM
    }
    event ChangeOwner(address owner);
    // event 注册Asset
    event RegisterAsset(
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
    event AddSafeContract(address _contract);
    // event remove contract
    event RemoveSafeContract(address _contract);

    //  name
    string private _name;
    //  symbol
    string private _symbol;
    //  supply
    uint256 private _supply;
    // account Id
    uint256 private accountId;
    // avatar Id
    uint256 private avatarId;
    // owner
    address private _owner;

    // constructor
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _supply = supply_;
        _owner = msg.sender;
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

    struct Change {
        address _asset;
        uint256 _accountId;
    }

    // Mapping from address to operator
    mapping(address => bool) private _isOperatorByAddress;

    // Mapping from address to trust contract
    mapping(address => bool) private _safeContracts;

    // Mapping from account Id to contract
    mapping(uint256 => mapping(address => bool))
        private _isTrustContractByAccountId;

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
        return _balancesById[_addressesToIds[owner]];
    }

    function balanceOfById(uint256 ownerId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balancesById[ownerId];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _accountsById[_ownersById[tokenId]]._address;
    }

    function ownerOfById(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _ownersById[tokenId];
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
    {}

    function _baseURI() internal view virtual returns (string memory) {}

    function approve(address to, uint256 tokenId) public virtual override {
        _approveInternal(_addressesToIds[to], tokenId, false);
    }

    function approveById(uint256 to, uint256 tokenId) public virtual override {
        _approveInternal(to, tokenId, true);
    }

    function _approveInternal(
        uint256 toId,
        uint256 tokenId,
        bool isById
    ) internal {
        uint256 owner = World.ownerOfById(tokenId);
        require(toId != owner, "W01");
        uint256 senderId = _addressesToIds[msg.sender];
        require(
            senderId == owner || isApprovedForAllById(owner, senderId),
            "W02"
        );
        _approve(toId, tokenId, isById);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_exists(tokenId), "W03");
        return _accountsById[_tokenApprovalsById[tokenId]]._address;
    }

    function getApprovedById(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(_exists(tokenId), "W03");
        return _tokenApprovalsById[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(
            _addressesToIds[msg.sender],
            _addressesToIds[operator],
            approved,
            false
        );
    }

    function setApprovalForAllById(uint256 operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(
            _addressesToIds[msg.sender],
            operator,
            approved,
            true
        );
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            _operatorApprovalsById[_addressesToIds[owner]][
                _addressesToIds[operator]
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_addressesToIds[msg.sender], tokenId),
            "W04"
        );
        _transfer(_addressesToIds[from], _addressesToIds[to], tokenId, false);
    }

    function transferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_addressesToIds[msg.sender], tokenId),
            "W04"
        );
        _transfer(from, to, tokenId, true);
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
            _isApprovedOrOwner(_addressesToIds[msg.sender], tokenId),
            "W04"
        );
        _safeTransfer(
            _addressesToIds[from],
            _addressesToIds[to],
            tokenId,
            _data,
            false
        );
    }

    function safeTransferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_addressesToIds[msg.sender], tokenId),
            "W04"
        );
        _safeTransfer(from, to, tokenId, _data, true);
    }

    function _safeTransfer(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory _data,
        bool isById
    ) internal virtual {
        _transfer(from, to, tokenId, isById);
        require(
            _checkOnERC721Received(
                _accountsById[from]._address,
                _accountsById[to]._address,
                tokenId,
                _data
            ),
            "W05"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownersById[tokenId] != 0;
    }

    function _isApprovedOrOwner(uint256 spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), "W03");
        uint256 owner = World.ownerOfById(tokenId);
        return (spender == owner ||
            isApprovedForAllById(owner, spender) ||
            getApprovedById(tokenId) == spender);
    }

    function mint(uint256 toId) public {
        onlyOwner();
        require(avatarId <= _supply, "minting is already finished");
        avatarId++;
        _mint(toId, avatarId);
    }

    function burn(uint256 tokenId) public {
        onlyOwner();
        _burn(tokenId);
    }

    // function _safeMint(address to, uint256 tokenId) internal virtual {
    //     _safeMint(to, tokenId, "");
    // }

    // function _safeMint(
    //     address to,
    //     uint256 tokenId,
    //     bytes memory _data
    // ) internal virtual {
    //     uint256 toId = _addressesToIds[to];
    //     _mint(toId, tokenId);
    //     require(
    //         _checkOnERC721Received(address(0), to, tokenId, _data),
    //         "transfer to non ERC721Receiver implementer"
    //     );
    // }

    function _mint(uint256 toId, uint256 tokenId) internal virtual {
        require(toId != 0, "W06");
        require(!_exists(tokenId), "W07");

        _balancesById[toId] += 1;
        _ownersById[tokenId] = toId;
        emit Transfer(address(0), _accountsById[toId]._address, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = World.ownerOf(tokenId);
        _approve(0, tokenId, false);
        uint256 ownerId = _addressesToIds[owner];
        _balancesById[ownerId] -= 1;
        delete _ownersById[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bool isById
    ) internal virtual {
        require(
            _ownersById[tokenId] == from,
            "W08"
        );
        require(to != 0, "W06");
        _approve(0, tokenId, true);
        _balancesById[from] -= 1;
        _balancesById[to] += 1;
        _ownersById[tokenId] = to;
        if (isById) {
            emit TransferById(from, to, tokenId);
        } else {
            emit Transfer(
                _accountsById[from]._address,
                _accountsById[to]._address,
                tokenId
            );
        }
    }

    function _approve(
        uint256 to,
        uint256 tokenId,
        bool isById
    ) internal virtual {
        _tokenApprovalsById[tokenId] = to;
        if (isById) {
            emit ApprovalById(World.ownerOfById(tokenId), to, tokenId);
        } else {
            emit Approval(
                World.ownerOf(tokenId),
                _accountsById[to]._address,
                tokenId
            );
        }
    }

    function _setApprovalForAll(
        uint256 owner,
        uint256 operator,
        bool approved,
        bool isById
    ) internal virtual {
        require(owner != operator, "W01");
        _operatorApprovalsById[owner][operator] = approved;
        if (isById) {
            emit ApprovalForAllById(owner, operator, approved);
        } else {
            emit ApprovalForAll(
                _accountsById[owner]._address,
                _accountsById[operator]._address,
                approved
            );
        }
    }

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
                    revert("W05");
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
        require(_address != address(0), "W09");
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
        _address = _accountsById[_id]._address;
    }

    // func 注册cash
    function registerAsset(
        address _contract,
        TypeOperation _typeOperation,
        string calldata _tokneName,
        string calldata _image
    ) public {
        onlyOwner();
        require(
            _contract != address(0) && _assets[_contract]._isExist == false,
            "W10"
        );
        require(
            msg.sender == IAsset(_contract).worldAddress(),
            "W11"
        );
        Asset memory asset = Asset(
            uint8(_typeOperation),
            true,
            _contract,
            _tokneName,
            _image
        );
        _assets[_contract] = asset;
        emit RegisterAsset(uint8(_typeOperation), _contract, _name, _image);
    }

    // func 修改Asset _contract
    function changeAsset(address _contract, Asset memory asset) public {
        onlyOwner();
        require(
            _contract != address(0) &&
                _assets[_contract]._isExist == true &&
                _assets[_contract]._type == asset._type,
            "W12"
        );
        _assets[_contract] = asset;
        emit ChangeAsset(_contract, asset._name, asset._image);
    }

    // func 创建Account
    function createAccount(address _address) public {
        require(
            _address != address(0) && _addressesToIds[_address] != 0,
            "W13"
        );
        accountId++;
        uint256 id = accountId;
        _accountsById[id] = Account(0, false, true, id, _address);
        _addressesToIds[_address] = id;
        emit CreateAccount(id, _address);
    }

    // func world修改Account _address
    function changeAccountByOperator(uint256 _id, address _newAddress) public {
        require(
            _isOperatorByAddress[msg.sender] == true || _owner == msg.sender,
            "W14"
        );
        require(
            _id != 0 &&
                _accountsById[_id]._isExist == true &&
                _addressesToIds[_newAddress] != 0,
            "W13"
        );
        Account memory account = _accountsById[_id];
        delete _addressesToIds[account._address];
        account._address = _newAddress;
        _accountsById[_id] = account;
        _addressesToIds[_newAddress] = _id;
        emit ChangeAccount(_id, msg.sender, _newAddress);
    }

    function changeAssertAccountAddressByOperator(Change[] calldata _changes)
        public
    {
        require(
            _isOperatorByAddress[msg.sender] == true || _owner == msg.sender,
            "W14"
        );
        require(
            _changes.length > 0,
            "W15"
        );

        for (uint256 i = 0; i < _changes.length; i++) {
            require(
                _changes[i]._asset != address(0) &&
                    _assets[_changes[i]._asset]._isExist == true,
                "W16"
            );

            require(
                    _accountsById[_changes[i]._accountId]._isExist == true,
                "W17"
            );

            IAsset(_changes[i]._asset).changeAccountAddress(
                _changes[i]._accountId,
                _accountsById[_changes[i]._accountId]._address
            );
        }
    }

    // func user修改Account _address
    function changeAccountByUser(uint256 _id, address _newAddress) public {
        require(
            _id != 0 &&
                _accountsById[_id]._isExist == true &&
                _addressesToIds[_newAddress] != 0 &&
                _accountsById[_id]._address == msg.sender,
            "W17"
        );

        Account memory account = _accountsById[_id];
        delete _addressesToIds[account._address];
        account._address = _newAddress;
        _accountsById[_id] = account;
        _addressesToIds[_newAddress] = _id;

        emit ChangeAccount(_id, msg.sender, _newAddress);
    }

    function changeAssertAccountAddressByUser(address[] calldata _addresses)
        public
    {
        require(_addresses.length > 0, "W15");
        uint256 id = _addressesToIds[msg.sender];
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "W09");
            IAsset(_addresses[i]).changeAccountAddress(id, msg.sender);
        }
    }

    // 添加operator
    function addOperator(address _operator) public {
        onlyOwner();
        require(_operator != address(0), "W09");
        _isOperatorByAddress[_operator] = true;
        emit AddOperator(_operator);
    }

    // 删除operator
    function removeOperator(address _operator) public {
        onlyOwner();
        delete _isOperatorByAddress[_operator];
        emit RemoveOperator(_operator);
    }

    // is operator
    function isOperator(address _operator) public view returns (bool) {
        return _isOperatorByAddress[_operator];
    }

    // 添加conttract
    function addContract(address _contract) public {
        onlyOwner();
        require(_contract != address(0), "W09");
        _safeContracts[_contract] = true;
        emit AddSafeContract(_contract);
    }

    // 删除contract
    function removeContract(address _contract) public {
        onlyOwner();
        delete _safeContracts[_contract];
        emit RemoveSafeContract(_contract);
    }

    function onlyOwner() internal view {
        require(_owner == msg.sender, "W18");
    }

    function changeOwner(address newOwner) public {
        onlyOwner();
        _owner = newOwner;
        emit ChangeOwner(_owner);
    }

    // is contract
    function isSafeContract(address _contract) public view returns (bool) {
        return _safeContracts[_contract];
    }

    // func 获取Account
    function getAccount(uint256 _id) public view returns (Account memory) {
        return _accountsById[_id];
    }

    // func 通过_address 获取Account
    function getAccountByAddress(address _address)
        public
        view
        returns (Account memory)
    {
        return _accountsById[_addressesToIds[_address]];
    }

    // func 获取Asset
    function getAsset(address _contract) public view returns (Asset memory) {
        return _assets[_contract];
    }

    function isTrust(address _contract, uint256 _id)
        public
        view
        virtual
        override
        returns (bool _isTrust)
    {
        require(
            _safeContracts[_contract] == true,
            "W19"
        );
        if (_accountsById[_id]._isTrustWorld == true) {
            return true;
        }
        require(
            _isTrustContractByAccountId[_id][_contract] == true,
            "W20"
        );
        return true;
    }
}
