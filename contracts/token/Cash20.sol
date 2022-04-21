//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/ICash20.sol";
import "../interfaces/IWorld.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Cash20 is Context, EIP712, ICash20 {
    mapping(uint256 => uint256) private _balancesById;
    mapping(uint256 => mapping(uint256 => uint256)) private _allowancesById;

    // nonce
    mapping(uint256 => uint256) private _noncesById;

    mapping(address => uint256) private _AddressesToIds;
    mapping(uint256 => address) private _IdsToAddresses;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address private _world;
    IWorld _iWorld;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
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
        _iWorld = IWorld(_world);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {ICash-balanceOf}.
     */
    function worldAddress() external view returns (address) {
        return _world;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOfById}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
       uint256 accountId =_AddressesToIds[account];
        return _balancesById[accountId];
    }

    /**
     * @dev See {ICash-balanceOf}.
     */
    function balanceOfById(uint256 account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balancesById[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {ICash-transferById}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero .
     * - the caller must have a balance of at least `amount`.
     */
    function transferById(uint256 to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(to != 0, "Cash: transfer to the zero Id");
        uint256 ownerId = _iWorld.getOrCreateAccountId(_msgSender());
        _transferById(ownerId, to, amount);
        return true;
    }

    function transferByBWO(
        uint256 to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) public virtual override returns (bool) {
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 ownerId = _AddressesToIds[owner];
        uint256 spenderId = _AddressesToIds[spender];
        return _allowancesById[ownerId][spenderId];
    }

    /**
     * @dev See {IERC20-allowanceById}.
     */
    function allowanceById(uint256 owner, uint256 spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowancesById[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approveById}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spenderId` cannot be the zero .
     */
    function approveById(uint256 spenderId, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        uint256 ownerId = _iWorld.getOrCreateAccountId(_msgSender());
        _approveById(ownerId, spenderId, amount);
        return true;
    }

    function approveByBWO(
        uint256 spender,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) public virtual override returns (bool) {
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev See {ICash-transferFromById}.
     *
     * Emits an {ApprovalById} event indicating the updated allowance.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero .
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFromById(
        uint256 from,
        uint256 to,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 spenderId = _iWorld.getOrCreateAccountId(_msgSender());
        _spendAllowanceById(from, spenderId, amount);
        _transferById(from, to, amount);
        return true;
    }

    function transferFromByBWO(
        uint256 from,
        uint256 to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) public virtual override returns (bool) {
        return true;
    }

    function changeAccountAddress(
        uint256 id,
        address oldAddr,
        address newAddr
    ) public virtual override returns (bool) {
        require(_world != _msgSender(), "Cash: must be the world");

        _IdsToAddresses[id] = newAddr;
        _AddressesToIds[newAddr] = id;
        _AddressesToIds[oldAddr] = 0;
        
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "Cash: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Cash: transfer from the zero address");
        require(to != address(0), "Cash: transfer to the zero address");

        uint256 fromId = _getIdByAddress(from);
        uint256 toId = _getIdByAddress(to);

        uint256 fromBalance = _balancesById[fromId];
        require(fromBalance >= amount, "ICash transfer amount exceeds balance");
        unchecked {
            _balancesById[fromId] = fromBalance - amount;
        }
        _balancesById[toId] += amount;

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {TransferById} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero .
     * - `to` cannot be the zero .
     * - `from` must have a balance of at least `amount`.
     */
    function _transferById(
        uint256 from,
        uint256 to,
        uint256 amount
    ) internal virtual {
        require(from != 0, "Cash: transfer from the zero address");
        require(to != 0, "Cash: transfer to the zero address");
         _getAddressById(from);
         _getAddressById(to);
        uint256 fromBalance = _balancesById[from];
        require(fromBalance >= amount, "ICash transfer amount exceeds balance");
        unchecked {
            _balancesById[from] = fromBalance - amount;
        }
        _balancesById[to] += amount;

        emit TransferById(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Cash: mint to the zero address");
        uint256 accountId = _getIdByAddress(account);

        _totalSupply += amount;
        _balancesById[accountId] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Cash: burn from the zero address");
        uint256 accountId = _getIdByAddress(account);
        uint256 accountBalance = _balancesById[accountId];
        require(accountBalance >= amount, "Cash: burn amount exceeds balance");
        unchecked {
            _balancesById[accountId] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Cash: approve from the zero address");
        require(spender != address(0), "ICash approve to the zero address");

        uint256 ownerId = _getIdByAddress(owner);
        uint256 spenderId = _getIdByAddress(spender);
        _allowancesById[ownerId][spenderId] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {ApprovalById} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero .
     * - `spender` cannot be the zero .
     */
    function _approveById(
        uint256 ownerId,
        uint256 spenderId,
        uint256 amount
    ) internal virtual {
        require(ownerId != 0, "Cash: approve from the zero ");
        require(spenderId != 0, "Cash: approve to the zero ");

         _getAddressById(ownerId);
         _getAddressById(spenderId);

        _allowancesById[ownerId][spenderId] = amount;
        emit ApprovalById(ownerId, spenderId, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Cash: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {ApprovalById} event.
     */
    function _spendAllowanceById(
        uint256 owner,
        uint256 spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowanceById(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Cash: insufficient allowance");
            unchecked {
                _approveById(owner, spender, currentAllowance - amount);
            }
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


}
