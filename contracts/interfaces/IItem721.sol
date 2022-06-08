//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./IItem721BWO.sol";
import "./IAsset.sol";

interface IItem721 is IERC721Metadata, IItem721BWO, IAsset {
    event TransferItem(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId
    );

    event ApprovalItem(
        uint256 indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAllItem(
        uint256 indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOfItem(uint256 owner) external view returns (uint256 balance);

    function ownerOfItem(uint256 tokenId) external view returns (uint256 owner);

    function isApprovedForAllItem(uint256 owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFromItem(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function safeTransferFromItem(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function transferFromItem(
        uint256 sender,
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function approveItem(
        uint256 from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAllItem(
        uint256 owner,
        address operator,
        bool _approved
    ) external;
}
