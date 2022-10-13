//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./IAsset.sol";

interface IAsset721 is IERC721Metadata, IAsset {
    event AssetTransfer(
        uint256 indexed from,
        uint256 to,
        uint256 indexed tokenId,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    event AssetApproval(
        uint256 indexed ownerId,
        address spender,
        uint256 indexed tokenId,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    event AssetApprovalForAll(
        uint256 indexed from,
        address indexed to,
        bool approved,
        bool isBWO,
        address indexed sender,
        uint256 nonce
    );

    function balanceOf(uint256 account) external view returns (uint256 balance);

    function ownerAccountOf(uint256 tokenId) external view returns (uint256 account);

    function transferFrom(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function transferFromBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function safeTransferFrom(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFromBWO(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes memory data,
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

    function setApprovalForAll(
        uint256 from,
        address to,
        bool approved
    ) external;

    function setApprovalForAllBWO(
        uint256 from,
        address to,
        bool approved,
        address sender,
        uint256 deadline,
        bytes memory signature
    ) external;

    function isApprovedForAll(uint256 owner, address operator) external view returns (bool);

    function itemsOf(
        uint256 owner,
        uint256 startAt,
        uint256 endAt
    ) external view returns (uint256[] memory tokenIds);
}
