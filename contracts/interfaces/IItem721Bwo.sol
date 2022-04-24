//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IItem721Bwo {
    event TransferByBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId
    );

    event ApprovalByBWO(
        uint256 indexed owner,
        uint256 indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAllByBWO(
        uint256 indexed owner,
        uint256 indexed operator,
        bool approved
    );

    function safeTransferFromByBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata data,
        bytes memory signature
    ) external;

    function safeTransferFromByBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    function transferFromByBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    function approveByBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    function setApprovalForAllByBWO(
        uint256 sender,
        uint256 operator,
        bool _approved,
        uint256 deadline,
        bytes memory signature
    ) external;
}
