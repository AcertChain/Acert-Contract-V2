//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IItem721BWO {
    event TransferItemBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId,
        address indexed sender,
        uint256 indexed nonce,
        uint256 indexed deadline
    );

    event ApprovalBWO(
        address indexed to,
        uint256 indexed tokenId,
        address indexed sender,
        uint256 indexed nonce,
        uint256 indexed deadline
    );

    event ApprovalForAllItemBWO(
        uint256 indexed from,
        address indexed to,
        bool approved,
        address indexed sender,
        uint256 indexed nonce,
        uint256 indexed deadline
    );

    function safeTransferFromItemBWO(
        uint256 spender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function safeTransferFromItemBWO(
        uint256 spender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function transferFromItemBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function approveBWO(
        address to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function setApprovalForAllItemBWO(
        uint256 from,
        address to,
        bool approved,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;
}
