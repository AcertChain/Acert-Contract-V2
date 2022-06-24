# Solidity API

## Cash20

### _balancesById

```solidity
mapping(uint256 => uint256) _balancesById
```

### _allowancesById

```solidity
mapping(uint256 => mapping(address => uint256)) _allowancesById
```

### _nonces

```solidity
mapping(address => uint256) _nonces
```

### _totalSupply

```solidity
uint256 _totalSupply
```

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

### constructor

```solidity
constructor(string name_, string symbol_, string version_, address world_) public
```

### name

```solidity
function name() public view virtual returns (string)
```

_Returns the name of the token._

### symbol

```solidity
function symbol() public view virtual returns (string)
```

_Returns the symbol of the token, usually a shorter version of the
name._

### decimals

```solidity
function decimals() public view virtual returns (uint8)
```

_Returns the number of decimals used to get its user representation.
For example, if `decimals` equals `2`, a balance of `505` tokens should
be displayed to a user as `5.05` (`505 / 10 ** 2`).

Tokens usually opt for a value of 18, imitating the relationship between
Ether and Wei. This is the value {ERC20} uses, unless this function is
overridden;

NOTE: This information is only used for _display_ purposes: it in
no way affects any of the arithmetic of the contract, including
{IERC20-balanceOf} and {IERC20-transfer}._

### totalSupply

```solidity
function totalSupply() public view virtual returns (uint256)
```

_See {IERC20-totalSupply}._

### balanceOf

```solidity
function balanceOf(address account) public view virtual returns (uint256)
```

_See {IERC20-balanceOf}._

### balanceOfCash

```solidity
function balanceOfCash(uint256 account) public view virtual returns (uint256)
```

_See {ICash-balanceOfCash}._

### transfer

```solidity
function transfer(address to, uint256 amount) public virtual returns (bool)
```

_See {IERC20-transfer}.

Requirements:

- `to` cannot be the zero address.
- the caller must have a balance of at least `amount`._

### transferCash

```solidity
function transferCash(uint256 from, uint256 to, uint256 amount) public virtual returns (bool)
```

_See {ICash-transferCash}._

### transferCashBWO

```solidity
function transferCashBWO(uint256 from, uint256 to, uint256 amount, address sender, uint256 deadline, bytes signature) public virtual returns (bool)
```

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) public virtual returns (bool)
```

_See {IERC20-transferFrom}.

Emits an {Approval} event indicating the updated allowance. This is not
required by the EIP. See the note at the beginning of {ERC20}.

NOTE: Does not update the allowance if the current allowance
is the maximum `uint256`.

Requirements:

- `from` and `to` cannot be the zero address.
- `from` must have a balance of at least `amount`.
- the caller must have allowance for ``from``'s tokens of at least
`amount`._

### _transfer

```solidity
function _transfer(address from, address to, uint256 amount) internal virtual
```

_Moves `amount` of tokens from `sender` to `recipient`.

This internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.

Emits a {Transfer} event.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `from` must have a balance of at least `amount`._

### _transferCash

```solidity
function _transferCash(uint256 from, uint256 to, uint256 amount) internal virtual
```

### approve

```solidity
function approve(address spender, uint256 amount) public virtual returns (bool)
```

_See {IERC20-approve}.

NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
`transferFrom`. This is semantically equivalent to an infinite approval.

Requirements:

- `spender` cannot be the zero address._

### approveCash

```solidity
function approveCash(uint256 ownerId, address spender, uint256 amount) public virtual returns (bool)
```

_See {IERC20-approveCash}._

### approveCashBWO

```solidity
function approveCashBWO(uint256 ownerId, address spender, uint256 amount, address sender, uint256 deadline, bytes signature) public virtual returns (bool)
```

### _approve

```solidity
function _approve(address owner, address spender, uint256 amount) internal virtual
```

_Sets `amount` as the allowance of `spender` over the `owner` s tokens.

This internal function is equivalent to `approve`, and can be used to
e.g. set automatic allowances for certain subsystems, etc.

Emits an {Approval} event.

Requirements:

- `owner` cannot be the zero address.
- `spender` cannot be the zero address._

### _approveId

```solidity
function _approveId(uint256 ownerId, address spender, uint256 amount) internal virtual
```

_Sets `amount` as the allowance of `spender` over the `owner` s tokens.

This internal function is equivalent to `approve`, and can be used to
e.g. set automatic allowances for certain subsystems, etc.

Emits an {ApprovalCash} event.

Requirements:

- `owner` cannot be the zero .
- `spender` cannot be the zero ._

### allowance

```solidity
function allowance(address owner, address spender) public view virtual returns (uint256)
```

_See {IERC20-allowance}._

### allowanceCash

```solidity
function allowanceCash(uint256 owner, address spender) public view virtual returns (uint256)
```

_See {IERC20-allowanceCash}._

### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
```

_Atomically increases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

- `spender` cannot be the zero address._

### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
```

_Atomically decreases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

- `spender` cannot be the zero address.
- `spender` must have allowance for the caller of at least
`subtractedValue`._

### _mint

```solidity
function _mint(address account, uint256 amount) internal virtual
```

_Creates `amount` tokens and assigns them to `account`, increasing
the total supply.

Emits a {Transfer} event with `from` set to the zero address.

Requirements:

- `account` cannot be the zero address._

### _mintCash

```solidity
function _mintCash(uint256 accountId, uint256 amount) internal virtual
```

### _burn

```solidity
function _burn(address account, uint256 amount) internal virtual
```

_Destroys `amount` tokens from `account`, reducing the
total supply.

Emits a {Transfer} event with `to` set to the zero address.

Requirements:

- `account` cannot be the zero address.
- `account` must have at least `amount` tokens._

### _burnCash

```solidity
function _burnCash(uint256 accountId, uint256 amount) internal virtual
```

### _getAccountIdByAddress

```solidity
function _getAccountIdByAddress(address addr) internal view returns (uint256)
```

### _getIdByAddress

```solidity
function _getIdByAddress(address addr) internal returns (uint256)
```

### _checkAddress

```solidity
function _checkAddress(address _addr, uint256 _id) internal view returns (bool)
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

