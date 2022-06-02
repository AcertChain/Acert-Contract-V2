//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IItem721BWO {
    event TransferItemBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId
    );

    event ApprovalItemBWO(
        uint256 indexed owner,
        uint256 indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAllItemBWO(
        uint256 indexed owner,
        address indexed operator,
        bool approved
    );

    function safeTransferFromItemBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory data,
        bytes memory signature
    ) external;

    function safeTransferFromItemBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    function transferFromItemBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    function approveItemBWO(
        address from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    function setApprovalForAllItemBWO(
        uint256 sender,
        address operator,
        bool _approved,
        uint256 deadline,
        bytes memory signature
    ) external;
}
