//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./IItem721BWO.sol";
import "./IAsset.sol";

interface IItem721 is IERC721Metadata, IItem721BWO, IAsset {
    event TransferId(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId
    );

    event ApprovalId(
        uint256 indexed owner,
        uint256 indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAllId(
        uint256 indexed owner,
        uint256 indexed operator,
        bool approved
    );

    function balanceOfId(uint256 owner) external view returns (uint256 balance);

    function ownerOfId(uint256 tokenId) external view returns (uint256 owner);

    function getApprovedId(uint256 tokenId)
        external
        view
        returns (uint256 operator);

    function isApprovedForAllId(uint256 owner, uint256 operator)
        external
        view
        returns (bool);

    function safeTransferItemFrom(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function safeTransferItemFrom(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function transferItemFrom(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function approveId(
        uint256 owner,
        uint256 to,
        uint256 tokenId
    ) external;

    function setApprovalForAllId(
        uint256 owner,
        uint256 operator,
        bool _approved
    ) external;
}
