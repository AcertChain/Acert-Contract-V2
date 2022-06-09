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

    event ApprovalItemBWO(
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
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId,
        bytes memory data,
        address indexed sender,
        uint256 indexed nonce,
        uint256 indexed deadline
    ) external;

    function safeTransferFromItemBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId,
        address indexed sender,
        uint256 indexed nonce,
        uint256 indexed deadline
    ) external;

    function transferFromItemBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId,
        address indexed sender,
        uint256 indexed nonce,
        uint256 indexed deadline
    ) external;

    function approveItemBWO(
        uint256 indexed from,
        address indexed to,
        uint256 indexed tokenId,
        address indexed sender,
        uint256 indexed nonce,
        uint256 indexed deadline
    ) external;

    function setApprovalForAllItemBWO(
        uint256 indexed from,
        address indexed to,
        bool approved,
        address indexed sender,
        uint256 indexed nonce,
        uint256 indexed deadline
    ) external;
}
