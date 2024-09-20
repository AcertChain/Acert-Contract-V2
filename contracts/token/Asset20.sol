//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../interfaces/IAsset20.sol";
import "../interfaces/IAcertContract.sol";
import "../interfaces/Mineable.sol";

contract Asset20 is IAsset20, ShellContract, IAcertContract, Mineable {
    function mint(uint256 accountId, uint256 amount) public onlyMiner {
        _mint(accountId, amount);
    }

    function burn(uint256 accountId, uint256 amount) public onlyMiner {
        _burn(accountId, amount);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function mintBatch(uint256[] calldata accountIds, uint256[] calldata amounts) public onlyOwner {
        require(accountIds.length == amounts.length, "MogaToken: accounts length not equal amounts length");
        for (uint256 i = 0; i < accountIds.length; i++) {
            _mint(accountIds[i], amounts[i]);
        }
    }

    function core() internal view returns (IAsset20Core) {
        return IAsset20Core(coreContract);
    }

    function emitTransfer(
        address from,
        address to,
        uint256 value
    ) public onlyCore {
        emit Transfer(from, to, value);
    }

    function emitApproval(
        address owner,
        address spender,
        uint256 value
    ) public onlyCore {
        emit Approval(owner, spender, value);
    }

    function emitAssetTransfer(
        uint256 from,
        uint256 to,
        uint256 value,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit AssetTransfer(from, to, value, isBWO, sender, nonce);
    }

    function emitAssetApproval(
        uint256 owner,
        address spender,
        uint256 value,
        bool isBWO,
        address sender,
        uint256 nonce
    ) public onlyCore {
        emit AssetApproval(owner, spender, value, isBWO, sender, nonce);
    }

    /**
     * @dev See {IAcertContract-vchainAddress}.
     */
    function vchainAddress() external view override returns (address) {
        return IAcertContract(coreContract).vchainAddress();
    }

    /**
     * @dev See {IERC20-name}.
     */
    function name() public view virtual override returns (string memory) {
        return core().name();
    }

    /**
     * @dev See {IERC20-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return core().symbol();
    }

    /**
     * @dev See {IERC20-decimals}.
     */
    function decimals() public view virtual override returns (uint8) {
        return core().decimals();
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return core().totalSupply();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return core().balanceOf(owner);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return core().allowance(owner, spender);
    }

    /**
     * @dev See {IAsset-protocol}.
     */
    function protocol() public view override returns (IAsset.ProtocolEnum) {
        return core().protocol();
    }

    /**
     * @dev See {IAsset-getNonce}.
     */
    function getNonce(address account) public view virtual override returns (uint256) {
        return core().getNonce(account);
    }

    /**
     * @dev See {IAsset20-balanceOf}.
     */
    function balanceOf(uint256 account) public view virtual override returns (uint256) {
        return core().balanceOf(account);
    }

    /**
     * @dev See {IAsset20-allowance}.
     */
    function allowance(uint256 ownerId, address spender) public view virtual override returns (uint256) {
        return core().allowance(ownerId, spender);
    }

    // transfer
    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        return core().transfer_(_msgSender(), to, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        return core().transferFrom_(_msgSender(), from, to, amount);
    }

    /**
     * @dev See {IAsset-transferFrom}.
     */
    function transferFrom(
        uint256 fromAccount,
        uint256 toAccount,
        uint256 amount
    ) public override returns (bool) {
        return core().transferFrom_(_msgSender(), fromAccount, toAccount, amount);
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
        bytes calldata signature
    ) public override returns (bool) {
        return core().transferFromBWO_(_msgSender(), fromAccount, toAccount, amount, sender, deadline, signature);
    }

    // approve
    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        return core().approve_(_msgSender(), spender, amount);
    }

    /**
     * @dev See {IAsset20-approve}.
     */
    function approve(
        uint256 ownerId,
        address spender,
        uint256 amount
    ) public override returns (bool) {
        return core().approve_(_msgSender(), ownerId, spender, amount);
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
        bytes calldata signature
    ) public override returns (bool) {
        return core().approveBWO_(_msgSender(), ownerId, spender, amount, sender, deadline, signature);
    }

    // mint & burn
    function _mint(uint256 account, uint256 amount) internal {
        return core().mint_(_msgSender(), account, amount);
    }

    function _burn(uint256 account, uint256 amount) internal {
        return core().burn_(_msgSender(), account, amount);
    }
}
