//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICash20BWO {
    event TransferCashBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 amount,
        address indexed sender,
        uint256 nonce,
        uint256 deadline
    );

    event ApprovalCashBWO(
        uint256 indexed owner,
        address indexed spender,
        uint256 amount,
        address indexed sender,
        uint256 nonce,
        uint256 deadline
    );

    function transferCashBWO(
        uint256 from,
        uint256 to,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

    function approveCashBWO(
        uint256 ownerId,
        address spender,
        uint256 amount,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);
}
