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
    mapping(uint256 => mapping(address => uint256)) private _allowancesById;
    // nonce
    mapping(address => uint256) private _nonces;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _world;
    address private _owner;

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
        _owner = _msgSender();
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

    function worldAddress() external view virtual override returns (address) {
        return _world;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balancesById[_getAccountIdByAddress(account)];
    }

    /**
     * @dev See {ICash-balanceOfCash}.
     */
    function balanceOfCash(uint256 account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balancesById[account];
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
        _transfer(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev See {ICash-transferCash}.
     */
    function transferCash(
        uint256 from,
        uint256 to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(from != 0, "Cash: from is the zero Id");
        require(to != 0, "Cash: transfer to the zero Id");
        if (_isTrust(_msgSender(), from)) {
            _transferCash(from, to, amount);
            return true;
        }

        _checkAndTransferCash(_msgSender(), from, to, amount);
        return true;
    }

    function transferCashBWO(
        uint256 from,
        uint256 to,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override returns (bool) {
        require(sender != address(0), "Cash: sender is the zero address");
        require(from != 0, "Cash: from is the zero Id");
        require(to != 0, "Cash: transfer to the zero Id");
        require(
            IWorld(_world).isBWO(_msgSender()),
            "Cash: must be the world BWO"
        );

        uint256 nonce = _nonces[sender];
        require(
            sender ==
                _recoverSig(
                    _hashTypedDataV4(
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "BWO(uint256 from,uint256 to,uint256 value,address sender,uint256 nonce,uint256 deadline)"
                                ),
                                from,
                                to,
                                amount,
                                sender,
                                nonce,
                                deadline
                            )
                        )
                    ),
                    signature
                ),
            "Cash: recoverSig failed"
        );

        require(block.timestamp < deadline, "Cash: signed transaction expired");
        _checkAndTransferCash(sender, from, to, amount);
        emit TransferCashBWO(from, to, amount, _nonces[sender]);
        _nonces[sender] += 1;
        return true;
    }

    function _checkAndTransferCash(
        address sender,
        uint256 from,
        uint256 to,
        uint256 amount
    ) internal virtual {
        if (_checkAddress(sender, from)) {
            return _transferCash(from, to, amount);
        }

        uint256 currentAllowance = allowanceCash(from, sender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Cash: insufficient allowance");
            unchecked {
                _approveId(from, sender, currentAllowance - amount);
            }
        }
        _transferCash(from, to, amount);
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
        return _allowancesById[_getAccountIdByAddress(owner)][spender];
    }

    /**
     * @dev See {IERC20-allowanceCash}.
     */
    function allowanceCash(uint256 owner, address spender)
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approveCash}.
     */
    function approveCash(
        uint256 ownerId,
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        require(spender != address(0), "Cash: approve to the zero address");
        require(_checkAddress(_msgSender(), ownerId), "Cash: not owner");

        _approveId(ownerId, spender, amount);
        return true;
    }

    function approveCashBWO(
        uint256 ownerId,
        address spender,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override returns (bool) {
        require(spender != address(0), "Cash: approve to the zero address");
        require(
            IWorld(_world).isBWO(_msgSender()),
            "Cash: must be the world BWO"
        );
        require(_checkAddress(sender, ownerId), "Cash: not owner");
        uint256 nonce = _nonces[sender];
        require(
            sender ==
                _recoverSig(
                    _hashTypedDataV4(
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "BWO(uint256 ownerId,address spender,uint256 amount,address sender,uint256 nonce,uint256 deadline)"
                                ),
                                ownerId,
                                spender,
                                amount,
                                sender,
                                nonce,
                                deadline
                            )
                        )
                    ),
                    signature
                ),
            "approveCashBWO : recoverSig failed"
        );

        require(
            block.timestamp < deadline,
            "approveCashBWO: signed transaction expired"
        );
        _approveId(ownerId, spender, amount);
        emit ApprovalCashBWO(ownerId, spender, amount, _nonces[sender]);
        _nonces[sender] += 1;
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
        if (_isTrust(_msgSender(), _getIdByAddress(from))) {
            _transfer(from, to, amount);
            return true;
        }
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
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
        require(fromBalance >= amount, "Cash: transfer amount exceeds balance");
        unchecked {
            _balancesById[fromId] = fromBalance - amount;
        }
        _balancesById[toId] += amount;

        emit Transfer(from, to, amount);
    }

    function _transferCash(
        uint256 from,
        uint256 to,
        uint256 amount
    ) internal virtual {
        uint256 fromBalance = _balancesById[from];
        require(fromBalance >= amount, "Cash: transfer amount exceeds balance");
        unchecked {
            _balancesById[from] = fromBalance - amount;
        }
        _balancesById[to] += amount;
        emit TransferCash(from, to, amount);
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
        _totalSupply += amount;
        _balancesById[_getIdByAddress(account)] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _mintCash(uint256 accountId, uint256 amount) internal virtual {
        require(accountId != 0, "Cash: mint to the zero Id");
        _totalSupply += amount;
        _balancesById[accountId] += amount;
        emit TransferCash(0, accountId, amount);
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

    function _burnCash(uint256 accountId, uint256 amount) internal virtual {
        require(accountId != 0, "Cash: burn from the zero Id");
        uint256 accountBalance = _balancesById[accountId];
        require(accountBalance >= amount, "Cash: burn amount exceeds balance");
        unchecked {
            _balancesById[accountId] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit TransferCash(accountId, 0, amount);
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
        require(spender != address(0), "Cash: approve to the zero address");

        _allowancesById[_getIdByAddress(owner)][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {ApprovalCash} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero .
     * - `spender` cannot be the zero .
     */
    function _approveId(
        uint256 ownerId,
        address spender,
        uint256 amount
    ) internal virtual {
        require(ownerId != 0, "Cash: approve from the zero Id");
        _allowancesById[ownerId][spender] = amount;
        emit ApprovalCash(ownerId, spender, amount);
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

    function _checkAddress(address addr, uint256 id)
        internal
        view
        returns (bool)
    {
        return IWorld(_world).checkAddress(addr, id);
    }

    function _isTrust(address _contract, uint256 _id)
        internal
        view
        returns (bool)
    {
        return IWorld(_world).isTrust(_contract, _id);
    }

    function _recoverSig(bytes32 digest, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(digest, signature);
    }
}
