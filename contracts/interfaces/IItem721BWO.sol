//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IItem721BWO {
    event TransferItemBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId,
        uint256 nonce
    );

    event ApprovalItemBWO(
        uint256 indexed owner,
        address indexed approved,
        uint256 indexed tokenId,
        uint256 nonce
    );

    event ApprovalForAllItemBWO(
        uint256 indexed owner,
        address indexed operator,
        bool approved,
        uint256 nonce
    );

    function safeTransferFromItemBWO(
        uint256 spender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory data,
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
        uint256 spender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function approveItemBWO(
        uint256 from,
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
