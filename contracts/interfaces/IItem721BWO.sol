//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IItem721BWO {
    event TransferItemBWO(
        uint256 indexed from,
        uint256 to,
        uint256 indexed tokenId,
        address indexed sender,
        uint256 nonce
    );

    event ApprovalItemBWO(
        address indexed to,
        uint256 indexed tokenId,
        address indexed sender,
        uint256 nonce
    );

    event ApprovalForAllItemBWO(
        uint256 indexed from,
        address indexed to,
        bool approved,
        address indexed sender,
        uint256 nonce
    );

    function safeTransferFromItemBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
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

    function approveItemBWO(
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
