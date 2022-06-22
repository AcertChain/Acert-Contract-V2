# Solidity API

## Item721

### _name

```solidity
string _name
```

### _symbol

```solidity
string _symbol
```

### _world

```solidity
address _world
```

### _owner

```solidity
address _owner
```

### _tokenURI

```solidity
string _tokenURI
```

### _nonces

```solidity
mapping(address => uint256) _nonces
```

### _ownersById

```solidity
mapping(uint256 => uint256) _ownersById
```

### _balancesById

```solidity
mapping(uint256 => uint256) _balancesById
```

### _tokenApprovalsById

```solidity
mapping(uint256 => address) _tokenApprovalsById
```

### _operatorApprovalsById

```solidity
mapping(uint256 => mapping(address => bool)) _operatorApprovalsById
```

### constructor

```solidity
constructor(string name_, string symbol_, string version_, string tokenURI_, address world_) public
```

_Initializes the contract by setting a `name` and a `symbol` to the token collection._

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### balanceOf

```solidity
function balanceOf(address owner) public view virtual returns (uint256)
```

_See {IERC721-balanceOf}._

### balanceOfItem

```solidity
function balanceOfItem(uint256 ownerId) public view virtual returns (uint256)
```

_See {IItem721-balanceOfItem}._

### ownerOf

```solidity
function ownerOf(uint256 tokenId) public view virtual returns (address)
```

_See {IERC721-ownerOf}._

### ownerOfItem

```solidity
function ownerOfItem(uint256 tokenId) public view virtual returns (uint256)
```

_See {IItem721-ownerOfItem}._

### name

```solidity
function name() public view virtual returns (string)
```

_Returns the token collection name._

### symbol

```solidity
function symbol() public view virtual returns (string)
```

_Returns the token collection symbol._

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view virtual returns (string)
```

_Returns the Uniform Resource Identifier (URI) for `tokenId` token._

### approve

```solidity
function approve(address to, uint256 tokenId) public virtual
```

_Gives permission to `to` to transfer `tokenId` token to another account.
The approval is cleared when the token is transferred.

Only a single account can be approved at a time, so approving the zero address clears previous approvals.

Requirements:

- The caller must own the token or be an approved operator.
- `tokenId` must exist.

Emits an {Approval} event._

### approveItemBWO

```solidity
function approveItemBWO(address to, uint256 tokenId, address sender, uint256 deadline, bytes signature) public virtual
```

### _approve

```solidity
function _approve(address to, uint256 tokenId) internal virtual
```

### getApproved

```solidity
function getApproved(uint256 tokenId) public view virtual returns (address)
```

_See {IERC721-getApproved}._

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) public virtual
```

_See {IERC721-setApprovalForAll}._

### setApprovalForAllItem

```solidity
function setApprovalForAllItem(uint256 from, address to, bool approved) public virtual
```

### setApprovalForAllItemBWO

```solidity
function setApprovalForAllItemBWO(uint256 from, address to, bool approved, address sender, uint256 deadline, bytes signature) public virtual
```

### _setApprovalForAllItem

```solidity
function _setApprovalForAllItem(uint256 owner, address operator, bool approved) internal virtual
```

### isApprovedForAll

```solidity
function isApprovedForAll(address owner, address operator) public view virtual returns (bool)
```

_See {IERC721-isApprovedForAll}._

### isApprovedForAllItem

```solidity
function isApprovedForAllItem(uint256 owner, address operator) public view virtual returns (bool)
```

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 tokenId) public virtual
```

_See {IERC721-transferFrom}._

### transferFromItem

```solidity
function transferFromItem(uint256 from, uint256 to, uint256 tokenId) public virtual
```

### transferFromItemBWO

```solidity
function transferFromItemBWO(uint256 from, uint256 to, uint256 tokenId, address sender, uint256 deadline, bytes signature) public virtual
```

### _transfer

```solidity
function _transfer(uint256 from, uint256 to, uint256 tokenId) internal virtual
```

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) public virtual
```

_Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
are aware of the ERC721 protocol to prevent tokens from being forever locked.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must exist and be owned by `from`.
- If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event._

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public virtual
```

_See {IERC721-safeTransferFrom}._

### safeTransferFromItem

```solidity
function safeTransferFromItem(uint256 from, uint256 to, uint256 tokenId, bytes data) public virtual
```

### safeTransferFromItemBWO

```solidity
function safeTransferFromItemBWO(uint256 from, uint256 to, uint256 tokenId, bytes data, address sender, uint256 deadline, bytes signature) public virtual
```

### _safeTransfer

```solidity
function _safeTransfer(uint256 from, uint256 to, uint256 tokenId, bytes data) internal virtual
```

### _exists

```solidity
function _exists(uint256 tokenId) internal view virtual returns (bool)
```

_Returns whether `tokenId` exists.

Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.

Tokens start existing when they are minted (`_mint`),
and stop existing when they are burned (`_burn`)._

### _isApprovedOrOwner

```solidity
function _isApprovedOrOwner(address sender, uint256 tokenId) internal view virtual returns (bool)
```

_Returns whether `spender` is allowed to manage `tokenId`.

Requirements:

- `tokenId` must exist._

### _safeMint

```solidity
function _safeMint(address to, uint256 tokenId) internal virtual
```

_Safely mints `tokenId` and transfers it to `to`.

Requirements:

- `tokenId` must not exist.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event._

### _safeMint

```solidity
function _safeMint(address to, uint256 tokenId, bytes data) internal virtual
```

_Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
forwarded in {IERC721Receiver-onERC721Received} to contract recipients._

### _mint

```solidity
function _mint(address to, uint256 tokenId) internal virtual
```

_Mints `tokenId` and transfers it to `to`.

WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible

Requirements:

- `tokenId` must not exist.
- `to` cannot be the zero address.

Emits a {Transfer} event._

### _mintItem

```solidity
function _mintItem(uint256 to, uint256 tokenId) internal virtual
```

### _burn

```solidity
function _burn(uint256 tokenId) internal virtual
```

_Destroys `tokenId`.
The approval is cleared when the token is burned.

Requirements:

- `tokenId` must exist.

Emits a {Transfer} event._

### _checkOnERC721Received

```solidity
function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes data) private returns (bool)
```

_Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
The call is not executed if the target address is not a contract._

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | address representing the previous owner of the given token ID |
| to | address | target address that will receive the tokens |
| tokenId | uint256 | uint256 ID of the token to be transferred |
| data | bytes | bytes optional data to send along with the call |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool whether the call correctly returned the expected magic value |

### _getAccountIdByAddress

```solidity
function _getAccountIdByAddress(address addr) internal view returns (uint256)
```

### _getIdByAddress

```solidity
function _getIdByAddress(address addr) internal returns (uint256)
```

### _getAddressById

```solidity
function _getAddressById(uint256 id) internal view returns (address)
```

### _checkAddress

```solidity
function _checkAddress(address addr, uint256 id) internal view returns (bool)
```

### _accountIsExist

```solidity
function _accountIsExist(uint256 _id) internal view returns (bool)
```

### _isBWO

```solidity
function _isBWO(address _add) internal view returns (bool)
```

### _isTrust

```solidity
function _isTrust(address _contract, uint256 _id) internal view returns (bool)
```

### _isFreeze

```solidity
function _isFreeze(uint256 _id) internal view returns (bool)
```

### getNonce

```solidity
function getNonce(address account) public view virtual returns (uint256)
```

### worldAddress

```solidity
function worldAddress() external view virtual returns (address)
```

### protocol

```solidity
function protocol() external pure virtual returns (enum IWorldAsset.ProtocolEnum)
```

### _recoverSig

```solidity
function _recoverSig(uint256 deadline, address signer, bytes32 digest, bytes signature) internal view
```

