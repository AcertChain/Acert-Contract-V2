//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICash20BWO {
    event TransferCashBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 value,
        uint256 nonce
    );

    event ApprovalCashBWO(
        uint256 indexed owner,
        uint256 indexed spender,
        uint256 value,
        uint256 nonce
    );

    function transferCashBWO(
        uint256 from,
        uint256 to,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

    function approveCashBWO(
        uint256 owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

}
