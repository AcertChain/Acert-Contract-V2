//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IWorld is IERC721Metadata {
    event TransferById(
        uint256 indexed from,
        uint256 indexed to,
        uint256 indexed tokenId
    );

    event ApprovalById(
        uint256 indexed owner,
        uint256 indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAllById(
        uint256 indexed owner,
        uint256 indexed operator,
        bool approved
    );

    function balanceOfById(uint256 owner)
        external
        view
        returns (uint256 balance);

    function ownerOfById(uint256 tokenId) external view returns (uint256 owner);

    function safeTransferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function safeTransferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function transferFromById(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function approveById(uint256 to, uint256 tokenId) external;

    function setApprovalForAllById(uint256 operator, bool _approved) external;

    function getApprovedById(uint256 tokenId)
        external
        view
        returns (uint256 operator);

    function isApprovedForAllById(uint256 owner, uint256 operator)
        external
        view
        returns (bool);

    function getOrCreateAccountId(address _address)
        external
        returns (uint256 id);

    function getAddressById(uint256 _id)
        external
        view
        returns (address _address);

    function isBWO(address _contract) external view returns (bool _isBWO);

    function isTrust(address _contract, uint256 _id)
        external
        view
        returns (bool _isTrust);
}
