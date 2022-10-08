//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IAsset20.sol";
import "../interfaces/IWorld.sol";
import "../interfaces/IMetaverse.sol";
import "../common/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Asset20 is Context, EIP712, IAsset20, Ownable {
    mapping(uint256 => uint256) private _balancesById;
    mapping(uint256 => mapping(address => uint256)) private _allowancesById;
    mapping(address => uint256) private _nonces;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    IWorld public world;
    IMetaverse public metaverse;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory version_,
        address world_
    ) EIP712(name_, version_) {
        _name = name_;
        _symbol = symbol_;
        world = IWorld(world_);
        metaverse = IMetaverse(world.getMetaverse());
    }

    function updateWorld(address _address) public onlyOwner {
        require(address(metaverse) == IWorld(_address).getMetaverse(), "Item: metaverse not match");
        world = IWorld(_address);
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
     * @dev See {IAsset-protocol}.
     */
    function protocol() external pure virtual override returns (IAsset.ProtocolEnum) {
        return IAsset.ProtocolEnum.ASSET20;
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
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        _checkAddrIsNotZero(owner, "Asset20: address zero is not a valid owner");
        return _balancesById[metaverse.getAccountIdByAddress(owner)];
    }

    /**
     * @dev See {IAsset-balanceOf}.
     */
    function balanceOf(uint256 accountId) public view virtual override returns (uint256) {
        _checkIdIsNotZero(accountId, "Asset20: id zero is not a valid owner");
        return _balancesById[accountId];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount, _msgSender());
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
        uint256 currentAllowance = allowance(from, _msgSender());
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Asset20: insufficient allowance");
            unchecked {
                _approveId(
                    metaverse.getAccountIdByAddress(from),
                    _msgSender(),
                    currentAllowance - amount,
                    false,
                    _msgSender()
                );
            }
        }
        _transfer(from, to, amount, _msgSender());
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
        uint256 amount,
        address sender
    ) internal virtual {
        require(from != address(0), "Asset20: transfer from the zero address");
        if (to == address(0)) {
            _burn(metaverse.getAccountIdByAddress(from), amount);
        } else {
            _transferAsset(
                metaverse.getAccountIdByAddress(from),
                metaverse.getOrCreateAccountId(to),
                amount,
                false,
                sender,
                from,
                to
            );
        }
    }

    /**
     * @dev See {IAsset-transferFrom}.
     */
    function transferFrom(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 amount
    ) public virtual override returns (bool) {
        if (metaverse.getAccountIdByAddress(_msgSender()) != fromAccount) {
            uint256 currentAllowance = allowance(fromAccount, _msgSender());
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "Asset20: insufficient allowance");
                unchecked {
                    _approveId(fromAccount, _msgSender(), currentAllowance - amount, false, _msgSender());
                }
            }
        }
        _transferAsset(
            fromAccount,
            toAccount,
            amount,
            true,
            _msgSender(),
            metaverse.getAddressByAccountId(fromAccount),
            metaverse.getAddressByAccountId(toAccount)
        );
        return true;
    }

    /**
     * @dev See {IAsset-transferBWO}.
     */
    function transferFromBWO(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override returns (bool) {
        world.checkBWOByAsset(_msgSender());
        transferBWOParamsVerify(fromAccount, toAccount, amount, sender, deadline, signature);
        _transferAsset(
            fromAccount,
            toAccount,
            amount,
            true,
            sender,
            metaverse.getAddressByAccountId(fromAccount),
            metaverse.getAddressByAccountId(toAccount)
        );
        return true;
    }

    function transferBWOParamsVerify(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        metaverse.checkSender(fromAccount, sender);
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            sender,
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BWO(uint256 fromAccount,uint256 toAccount,uint256 amount,address sender,uint256 nonce,uint256 deadline)"
                        ),
                        fromAccount,
                        toAccount,
                        amount,
                        sender,
                        nonce,
                        deadline
                    )
                )
            ),
            signature
        );
        return true;
    }

    function _transferAsset(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 amount,
        bool _isBWO,
        address _sender,
        address _fromAddr,
        address _toAddr
    ) internal virtual {
        require(!metaverse.isFreeze(fromAccount), "Asset20: transfer from frozen account");
        require(metaverse.accountIsExist(toAccount), "Asset20: to account is not exist");

        uint256 fromBalance = _balancesById[fromAccount];
        require(fromBalance >= amount, "Asset20: transfer amount exceeds balance");
        unchecked {
            _balancesById[fromAccount] = fromBalance - amount;
        }
        _balancesById[toAccount] += amount;
        emit Transfer(_fromAddr, _toAddr, amount);
        emit AssetTransfer(fromAccount, toAccount, amount, _isBWO, _sender, getNonce(_sender));
        _nonces[_sender] += 1;
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
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approveId(metaverse.getOrCreateAccountId(_msgSender()), spender, amount, false, _msgSender());
        return true;
    }

    /**
     * @dev See {IAsset20-approve}.
     */
    function approve(
        uint256 ownerId,
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        require(spender != address(0), "Asset20: approve to the zero address");
        metaverse.checkSender(ownerId, _msgSender());

        _approveId(ownerId, spender, amount, false, _msgSender());
        return true;
    }

    /**
     * @dev See {IAsset20-approveBWO}.
     */
    function approveBWO(
        uint256 ownerId,
        address spender,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public virtual override returns (bool) {
        world.checkBWOByAsset(_msgSender());
        approveBWOParamsVerify(ownerId, spender, amount, sender, deadline, signature);
        _approveId(ownerId, spender, amount, true, sender);
        return true;
    }

    function approveBWOParamsVerify(
        uint256 ownerId,
        address spender,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        metaverse.checkSender(ownerId, sender);
        uint256 nonce = _nonces[sender];
        _recoverSig(
            deadline,
            sender,
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
        );
        return true;
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
     * - `owner` cannot be the zero .
     * - `spender` cannot be the zero .
     */
    function _approveId(
        uint256 ownerId,
        address spender,
        uint256 amount,
        bool _isBWO,
        address _sender
    ) internal virtual {
        require(!metaverse.isFreeze(ownerId), "Asset20: approve owner is frozen");
        require(spender != address(0), "Asset20: approve to the zero address");
        _allowancesById[ownerId][spender] = amount;
        emit Approval(_sender, spender, amount);
        emit AssetApproval(ownerId, spender, amount, _isBWO, _sender, getNonce(_sender));
        _nonces[_sender] += 1;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowance(metaverse.getAccountIdByAddress(owner), spender);
    }

    /**
     * @dev See {IAsset20-allowance}.
     */
    function allowance(uint256 ownerId, address spender) public view virtual override returns (uint256) {
        if (world.isTrustByAsset(spender, ownerId)) {
            return type(uint256).max;
        }
        return _allowancesById[ownerId][spender];
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        uint256 ownerId = metaverse.getOrCreateAccountId(_msgSender());
        uint256 currentAllowance = _allowancesById[ownerId][spender];
        _approveId(ownerId, spender, currentAllowance + addedValue, false, _msgSender());
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 ownerId = metaverse.getOrCreateAccountId(_msgSender());
        uint256 currentAllowance = _allowancesById[ownerId][spender];
        require(currentAllowance >= subtractedValue, "Asset20: decreased allowance below zero");
        _approveId(ownerId, spender, currentAllowance - subtractedValue, false, _msgSender());

        return true;
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
    function _mint(address _address, uint256 amount) internal virtual {
        require(_address != address(0), "Asset20: mint to the zero address");
        _mint(metaverse.getOrCreateAccountId(_address), amount);
    }

    function _mint(uint256 accountId, uint256 amount) internal virtual {
        require(accountId != 0, "Asset20: mint to the zero Id");
        require(metaverse.accountIsExist(accountId), "Asset20: to account is not exist");

        _totalSupply += amount;
        _balancesById[accountId] += amount;
        emit Transfer(address(0), metaverse.getAddressByAccountId(accountId), amount);
        emit AssetTransfer(0, accountId, amount, false, _msgSender(), getNonce(_msgSender()));
        _nonces[_msgSender()] += 1;
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
    function _burn(address _address, uint256 amount) internal virtual {
        require(_address != address(0), "Asset20: burn from the zero address");
        _burn(metaverse.getAccountIdByAddress(_address), amount);
    }

    function _burn(uint256 accountId, uint256 amount) internal virtual {
        require(accountId != 0, "Asset20: burn from the zero Id");
        require(metaverse.accountIsExist(accountId), "Asset20: to account is not exist");

        uint256 accountBalance = _balancesById[accountId];
        require(accountBalance >= amount, "Asset20: burn amount exceeds balance");
        unchecked {
            _balancesById[accountId] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(metaverse.getAddressByAccountId(accountId), address(0), amount);
        emit AssetTransfer(accountId, 0, amount, false, _msgSender(), getNonce(_msgSender()));
        _nonces[_msgSender()] += 1;
    }

    function _checkIdIsNotZero(uint256 _id, string memory _msg) internal pure {
        require(_id != 0, _msg);
    }

    function _checkAddrIsNotZero(address _addr, string memory _msg) internal pure {
        require(_addr != address(0), _msg);
    }

    function getNonce(address account) public view virtual override returns (uint256) {
        return _nonces[account];
    }

    function _recoverSig(
        uint256 deadline,
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        require(block.timestamp < deadline, "Asset20: BWO call expired");
        require(signer == ECDSA.recover(digest, signature), "Asset20: recoverSig failed");
    }

    function worldAddress() external view override returns (address) {}
}
