//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICash20Bwo {
    event TransferByBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 value,
        uint256 nonce
    );

    event ApprovalByBWO(
        uint256 indexed owner,
        uint256 indexed spender,
        uint256 value,
        uint256 nonce
    );

    function transferByBWO(
        uint256 from,
        uint256 to,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

    function approveByBWO(
        uint256 owner,
        uint256 spender,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);

    function transferFromByBWO(
        uint256 spender,
        uint256 from,
        uint256 to,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external returns (bool);
}
