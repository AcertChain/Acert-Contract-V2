//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IItem721BWO {
    event TransferBWO(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId
    );

    event ApprovalBWO(
        uint256 indexed owner,
        uint256 indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAllBWO(
        uint256 indexed owner,
        uint256 indexed operator,
        bool approved
    );

    function safeTransferFromBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata data,
        bytes memory signature
    ) external;

    function transferFromBWO(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    function approveBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    function setApprovalForAllBWO(
        uint256 sender,
        uint256 operator,
        bool _approved,
        uint256 deadline,
        bytes memory signature
    ) external;
}
