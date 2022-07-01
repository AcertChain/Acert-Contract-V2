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

    event ApprovalForAllItem(
        uint256 indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOfItem(uint256 owner)
        external
        view
        returns (uint256 balance);

    function ownerOfItem(uint256 tokenId) external view returns (uint256 owner);

    function isApprovedForAllItem(uint256 owner, address operator)
        external
        view
        returns (bool);

    function itemsOf(
        uint256 owner,
        uint256 startAt,
        uint256 endAt
    ) external view returns (uint256[] memory tokenIds);

    function safeTransferFromItem(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function transferFromItem(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function setApprovalForAllItem(
        uint256 from,
        address to,
        bool approved
    ) external;
}
