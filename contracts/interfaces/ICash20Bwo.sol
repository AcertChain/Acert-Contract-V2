//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICash20BWO {
    event TransferBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 value,
        uint256 nonce
    );

    event ApprovalBWO(
        uint256 indexed owner,
        uint256 indexed spender,
        uint256 value,
        uint256 nonce
    );

    function transferBWO(
        uint256 from,
        uint256 to,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

    function approveBWO(
        uint256 owner,
        uint256 spender,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

    function transferFromBWO(
        uint256 spender,
        uint256 from,
        uint256 to,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);
}
