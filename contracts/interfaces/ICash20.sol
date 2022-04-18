//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ICash20 is IERC20Metadata {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event TransferById(uint256 indexed from, uint256 indexed to, uint256 value);

    event TransferByBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 value,
        uint256 nonce
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approveById}. `value` is the new allowance.
     */
    event ApprovalById(
        uint256 indexed owner,
        uint256 indexed spender,
        uint256 value
    );

    event ApprovalByBWO(
        uint256 indexed owner,
        uint256 indexed spender,
        uint256 value,
        uint256 nonce
    );

    /**
     * @dev Returns the amount of tokens owned by `account id`.
     */
    function balanceOfById(uint256 account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account id to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {TransferById} event.
     */
    function transferById(uint256 to, uint256 amount) external returns (bool);

    function transferByBWO(
        uint256 to,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom} or {transferFromById}. This is
     * zero by default.
     *
     * This value changes when {approve} or {approveById} or {transferFrom} or {transferFromById} are called.
     */
    function allowanceById(uint256 owner, uint256 spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {ApprovalById} event.
     */
    function approveById(uint256 spender, uint256 amount)
        external
        returns (bool);

    function approveById(
        uint256 spender,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from id` to `to id` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {TransferById} event.
     */
    function transferFromById(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);

    function transferFromByBWO(
        uint256 from,
        uint256 to,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /**
     * @dev Returns the name of the token.
     */
    function worldAddress() external view returns (address);

    function changeAccountAddress(
        uint256 id,
        address oldAddr,
        address newAddr
    ) external returns (bool);
}
